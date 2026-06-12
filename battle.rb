require 'json'

PLAYER_POINTS   = 100
OPPONENT_POINTS = 60
MAX_ROUNDS      = 300
HP_PER_CON      = 20
DR_PER_AGI      = 0.5

OPPONENT_ARCHETYPES = {
  'brawler'    => { 'str' => 0.60, 'agi' => 0.10, 'con' => 0.30 },
  'sentinel'   => { 'str' => 0.20, 'agi' => 0.60, 'con' => 0.20 },
  'juggernaut' => { 'str' => 0.25, 'agi' => 0.15, 'con' => 0.60 },
  'assassin'   => { 'str' => 0.75, 'agi' => 0.15, 'con' => 0.10 },
  'paladin'    => { 'str' => 0.34, 'agi' => 0.33, 'con' => 0.33 },
}.freeze

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

def make_character(str:, agi:, con:)
  { str: str, agi: agi, con: con, hp: con * HP_PER_CON, dr: agi * DR_PER_AGI }
end

def generate_opponent(archetype_name)
  weights = OPPONENT_ARCHETYPES[archetype_name]
  raise "Unknown opponent archetype: #{archetype_name}" unless weights
  stats = allocate_points(weights, OPPONENT_POINTS)
  make_character(str: stats['str'], agi: stats['agi'], con: stats['con'])
end

def tournament(player, seed: 42)
  opponents = OPPONENT_ARCHETYPES.keys.map { |name| generate_opponent(name) }
  rng = Random.new(seed)
  bracket = opponents.shuffle(random: rng)
  a_hp = player[:hp].to_f
  fights = []
  bracket.each do |opp|
    b_hp = opp[:hp].to_f
    rounds = 0
    while a_hp > 0 && b_hp > 0 && rounds < MAX_ROUNDS
      rounds += 1
      a_takes = [opp[:str] - player[:dr] + rng.rand(-1..1), 0].max
      b_takes = [player[:str] - opp[:dr] + rng.rand(-1..1), 0].max
      a_hp -= a_takes
      b_hp -= b_takes
    end
    winner = a_hp > b_hp ? 'player' : 'opponent'
    fights << { winner: winner, player_hp_after: a_hp.round(1), rounds: rounds }
    break if winner != 'player'
  end
  won_all = fights.length == opponents.length && fights.all? { |f| f[:winner] == 'player' }
  { winner: won_all ? 'player' : 'opponent', fights_completed: fights.length, final_player_hp: a_hp.round(1) }
end

def simulate_tournament(player, seeds: (1..100).to_a)
  results = seeds.map { |s| tournament(player, seed: s) }
  wins = results.count { |r| r[:winner] == 'player' }
  { simulations: seeds.size, wins: wins, win_pct: (wins.to_f / seeds.size * 100).round(1) }
end

if __FILE__ == $0
  if ARGV.length < 3
    puts "Usage:"
    puts "  ruby battle.rb <str> <agi> <con> --simulate"
    puts "  ruby battle.rb <str> <agi> <con> [seed]"
    puts ""
    puts "Player budget: #{PLAYER_POINTS} points (str + agi + con must equal #{PLAYER_POINTS}, min 1 each)"
    puts "Opponents: #{OPPONENT_ARCHETYPES.keys.join(', ')}"
    exit 1
  end

  s, a, c = ARGV[0].to_i, ARGV[1].to_i, ARGV[2].to_i
  player = make_character(str: s, agi: a, con: c)

  if ARGV.include?('--simulate')
    puts JSON.pretty_generate(simulate_tournament(player))
  else
    seed = ARGV[3]&.to_i || 42
    puts JSON.pretty_generate(tournament(player, seed: seed))
  end
end
