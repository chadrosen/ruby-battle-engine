require 'json'

# Battle Engine
# Stats:
#   strength     - damage dealt per round (flat)
#   agility      - damage reduction (0.5 per point, min 0 damage taken)
#   constitution - hit points (20 per point)
# Each attack has ±1 variance (seeded RNG)
# Battle: simultaneous attacks each round, first to 0 HP loses
# If both reach 0 same round: higher remaining HP wins (least negative)
# If 300 rounds without winner: higher remaining HP wins

MAX_ROUNDS = 300
HP_PER_CON = 20
DR_PER_AGI = 0.5

CHARS_FILE = File.join(__dir__, 'characters.json')
CHARS = JSON.parse(File.read(CHARS_FILE))
ARCHETYPES = CHARS['archetypes']
RULES = CHARS['rules']

def make_character(str:, agi:, con:)
  {
    str: str,
    agi: agi,
    con: con,
    hp: con * HP_PER_CON,
    dr: agi * DR_PER_AGI
  }
end

# Distribute total points across str/agi/con using archetype weights.
# Uses largest-remainder method to ensure the allocation sums exactly to total.
# Minimum 1 point per stat.
def allocate_points(weights, total)
  stats = %w[str agi con]
  ideal = stats.map { |s| weights[s].to_f * total }
  alloc = ideal.map { |v| [v.floor, 1].max }

  leftover = total - alloc.sum
  if leftover > 0
    order = stats.each_index.sort_by { |i| -(ideal[i] - ideal[i].floor) }
    order.first(leftover).each { |i| alloc[i] += 1 }
  end

  stats.zip(alloc).to_h
end

def generate_character(archetype_name)
  archetype = ARCHETYPES[archetype_name]
  stats = allocate_points(archetype['weights'], RULES['total_points'])
  char = make_character(str: stats['str'], agi: stats['agi'], con: stats['con'])
  char.merge(name: archetype_name)
end

def battle(char_a, char_b, seed: 42)
  rng = Random.new(seed)
  a_hp = char_a[:hp].to_f
  b_hp = char_b[:hp].to_f
  rounds = 0

  while a_hp > 0 && b_hp > 0 && rounds < MAX_ROUNDS
    rounds += 1
    a_takes = [char_b[:str] - char_a[:dr] + rng.rand(-1..1), 0].max
    b_takes = [char_a[:str] - char_b[:dr] + rng.rand(-1..1), 0].max
    a_hp -= a_takes
    b_hp -= b_takes
  end

  if a_hp > b_hp
    { winner: :a, rounds: rounds, a_hp: a_hp.round(1), b_hp: b_hp.round(1) }
  elsif b_hp > a_hp
    { winner: :b, rounds: rounds, a_hp: a_hp.round(1), b_hp: b_hp.round(1) }
  else
    { winner: :tie, rounds: rounds, a_hp: a_hp.round(1), b_hp: b_hp.round(1) }
  end
end

def simulate(char_a, char_b, seeds: (1..100).to_a)
  results = seeds.map { |s| battle(char_a, char_b, seed: s) }
  wins_a = results.count { |r| r[:winner] == :a }
  wins_b = results.count { |r| r[:winner] == :b }
  ties   = results.count { |r| r[:winner] == :tie }
  rounds = results.map { |r| r[:rounds] }

  {
    simulations: seeds.size,
    wins_a: wins_a,
    wins_b: wins_b,
    ties: ties,
    win_pct_a: (wins_a.to_f / seeds.size * 100).round(1),
    win_pct_b: (wins_b.to_f / seeds.size * 100).round(1),
    avg_rounds: (rounds.sum.to_f / rounds.size).round(1),
    min_rounds: rounds.min,
    max_rounds: rounds.max
  }
end

# Tournament: player fights one generated opponent per archetype.
# Each fight starts with full HP — no carry-over. Fight order is shuffled by seed.
# The main RNG seeds each individual fight, keeping everything deterministic.
def tournament(char_a, seed: 42)
  opponents = ARCHETYPES.keys.map { |name| generate_character(name) }

  rng = Random.new(seed)
  opponents = opponents.shuffle(random: rng)

  fights = opponents.map do |opp|
    result = battle(char_a, opp, seed: rng.rand(100_000))
    {
      opponent: opp[:name],
      opponent_str: opp[:str],
      opponent_agi: opp[:agi],
      opponent_con: opp[:con],
      winner: result[:winner] == :a ? 'player' : 'opponent',
      player_hp: result[:a_hp],
      opponent_hp: result[:b_hp],
      rounds: result[:rounds]
    }
  end

  wins = fights.count { |f| f[:winner] == 'player' }
  {
    winner: wins == opponents.length ? 'player' : 'opponent',
    fights_won: wins,
    total_fights: opponents.length,
    fights: fights
  }
end

def simulate_tournament(char_a, seeds: (1..100).to_a)
  results = seeds.map { |s| tournament(char_a, seed: s) }
  wins = results.count { |r| r[:winner] == 'player' }
  avg_wins = results.sum { |r| r[:fights_won] }.to_f / seeds.size

  {
    simulations: seeds.size,
    tournament_wins: wins,
    tournament_losses: seeds.size - wins,
    win_pct: (wins.to_f / seeds.size * 100).round(1),
    avg_fights_won: avg_wins.round(2)
  }
end

if __FILE__ == $0
  if ARGV.length < 3
    puts "Usage:"
    puts "  ruby battle.rb <str> <agi> <con> <str_b> <agi_b> <con_b> [seed]"
    puts "  ruby battle.rb <str> <agi> <con> <str_b> <agi_b> <con_b> --simulate"
    puts "  ruby battle.rb <str> <agi> <con> --tournament [seed]"
    puts "  ruby battle.rb <str> <agi> <con> --tournament --simulate"
    exit 1
  end

  a = make_character(str: ARGV[0].to_i, agi: ARGV[1].to_i, con: ARGV[2].to_i)

  if ARGV.include?('--tournament')
    if ARGV.include?('--simulate')
      result = simulate_tournament(a)
    else
      seed = ARGV.drop(3).reject { |x| x == '--tournament' }.first&.to_i || 42
      result = tournament(a, seed: seed)
    end
  elsif ARGV.length >= 6
    b = make_character(str: ARGV[3].to_i, agi: ARGV[4].to_i, con: ARGV[5].to_i)
    if ARGV[6] == '--simulate'
      result = simulate(a, b)
    else
      seed = ARGV[6]&.to_i || 42
      result = battle(a, b, seed: seed)
    end
  else
    puts "Error: provide opponent stats or --tournament flag"
    exit 1
  end

  puts JSON.pretty_generate(result)
end
