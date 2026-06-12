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
OPPONENTS = CHARS['opponents']
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

# Tournament: fight the first `level` opponents (sorted by level) in a random bracket
# order determined by the seed. HP carries over between fights.
# Returns winner ('a' or 'b') and fight-by-fight details.
def tournament(char_a, level:, seed: 42)
  bracket = OPPONENTS.values
    .sort_by { |o| o['level'] }
    .first(level)

  rng = Random.new(seed)
  bracket = bracket.shuffle(random: rng)

  a_hp = char_a[:hp].to_f
  fights = []

  bracket.each do |opp_data|
    char_b = make_character(str: opp_data['str'], agi: opp_data['agi'], con: opp_data['con'])
    b_hp = char_b[:hp].to_f
    rounds = 0

    while a_hp > 0 && b_hp > 0 && rounds < MAX_ROUNDS
      rounds += 1
      a_takes = [char_b[:str] - char_a[:dr] + rng.rand(-1..1), 0].max
      b_takes = [char_a[:str] - char_b[:dr] + rng.rand(-1..1), 0].max
      a_hp -= a_takes
      b_hp -= b_takes
    end

    winner = a_hp > b_hp ? 'a' : 'b'
    fights << {
      opponent: opp_data['level'],
      winner: winner,
      a_hp_after: a_hp.round(1),
      rounds: rounds
    }
    break if winner != 'a'
  end

  won_all = fights.length == level && fights.all? { |f| f[:winner] == 'a' }
  {
    winner: won_all ? 'a' : 'b',
    fights_completed: fights.length,
    final_a_hp: a_hp.round(1),
    fights: fights
  }
end

def simulate_tournament(char_a, level:, seeds: (1..100).to_a)
  results = seeds.map { |s| tournament(char_a, level: level, seed: s) }
  wins = results.count { |r| r['winner'] == 'a' }

  {
    simulations: seeds.size,
    level: level,
    wins: wins,
    win_pct: (wins.to_f / seeds.size * 100).round(1),
    avg_fights_completed: (results.sum { |r| r[:fights_completed] }.to_f / seeds.size).round(1)
  }
end

if __FILE__ == $0
  if ARGV.length < 3
    puts "Usage:"
    puts "  ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> [seed]"
    puts "  ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> --simulate"
    puts "  ruby battle.rb <str_a> <agi_a> <con_a> --tournament --level N [seed]"
    puts "  ruby battle.rb <str_a> <agi_a> <con_a> --tournament --level N --simulate"
    exit 1
  end

  a = make_character(str: ARGV[0].to_i, agi: ARGV[1].to_i, con: ARGV[2].to_i)

  if ARGV.include?('--tournament')
    level_idx = ARGV.index('--level')
    level = level_idx ? ARGV[level_idx + 1].to_i : 4

    if ARGV.include?('--simulate')
      result = simulate_tournament(a, level: level)
    else
      seed_arg = ARGV.drop(3).reject { |x| ['--tournament', '--simulate', '--level'].include?(x) }
                     .reject { |x| level_idx && x == ARGV[level_idx + 1] }
                     .first
      seed = seed_arg&.to_i || 42
      result = tournament(a, level: level, seed: seed)
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
