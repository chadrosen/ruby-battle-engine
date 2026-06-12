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

# Run from command line: ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> [seed]
if __FILE__ == $0
  if ARGV.length < 6
    puts "Usage: ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> [seed]"
    puts "       ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> --simulate"
    exit 1
  end

  a = make_character(str: ARGV[0].to_i, agi: ARGV[1].to_i, con: ARGV[2].to_i)
  b = make_character(str: ARGV[3].to_i, agi: ARGV[4].to_i, con: ARGV[5].to_i)

  if ARGV[6] == '--simulate'
    result = simulate(a, b)
    puts JSON.pretty_generate(result)
  else
    seed = ARGV[6]&.to_i || 42
    result = battle(a, b, seed: seed)
    puts JSON.pretty_generate(result)
  end
end
