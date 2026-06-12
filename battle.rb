require 'json'

MAX_ROUNDS = 300
HP_PER_CON = 20
DR_PER_AGI = 0.5

CHARS_FILE = File.join(__dir__, 'characters.json')
CHARS = JSON.parse(File.read(CHARS_FILE))
OPPONENTS = CHARS['opponents']
RULES = CHARS['rules']

# Hidden player archetype weights — not exposed in characters.json.
# Names hint at stat profiles; exact stats must be inferred through testing.
PLAYER_ARCHETYPES = {
  # Berserker-type: high STR, low AGI, low CON
  'berserker'    => { 'str' => 0.70, 'agi' => 0.10, 'con' => 0.20 },
  'destroyer'    => { 'str' => 0.72, 'agi' => 0.08, 'con' => 0.20 },
  'annihilator'  => { 'str' => 0.75, 'agi' => 0.10, 'con' => 0.15 },
  'executioner'  => { 'str' => 0.68, 'agi' => 0.12, 'con' => 0.20 },
  'ravager'      => { 'str' => 0.65, 'agi' => 0.15, 'con' => 0.20 },
  'slayer'       => { 'str' => 0.70, 'agi' => 0.15, 'con' => 0.15 },
  'devastator'   => { 'str' => 0.73, 'agi' => 0.07, 'con' => 0.20 },
  'warlord'      => { 'str' => 0.65, 'agi' => 0.10, 'con' => 0.25 },
  'marauder'     => { 'str' => 0.68, 'agi' => 0.07, 'con' => 0.25 },
  'reaper'       => { 'str' => 0.72, 'agi' => 0.13, 'con' => 0.15 },
  # Tank-type: low STR, low AGI, high CON
  'ironclad'     => { 'str' => 0.15, 'agi' => 0.10, 'con' => 0.75 },
  'colossus'     => { 'str' => 0.15, 'agi' => 0.08, 'con' => 0.77 },
  'titan'        => { 'str' => 0.18, 'agi' => 0.07, 'con' => 0.75 },
  'fortress'     => { 'str' => 0.12, 'agi' => 0.10, 'con' => 0.78 },
  'bastion'      => { 'str' => 0.13, 'agi' => 0.12, 'con' => 0.75 },
  'bulwark'      => { 'str' => 0.16, 'agi' => 0.09, 'con' => 0.75 },
  'iron_wall'    => { 'str' => 0.14, 'agi' => 0.11, 'con' => 0.75 },
  'behemoth'     => { 'str' => 0.18, 'agi' => 0.07, 'con' => 0.75 },
  'immortal'     => { 'str' => 0.15, 'agi' => 0.10, 'con' => 0.75 },
  'stone_guard'  => { 'str' => 0.15, 'agi' => 0.10, 'con' => 0.75 },
  # Evasion-type: low STR, high AGI, low CON
  'phantom'      => { 'str' => 0.20, 'agi' => 0.65, 'con' => 0.15 },
  'shadow'       => { 'str' => 0.18, 'agi' => 0.67, 'con' => 0.15 },
  'wraith'       => { 'str' => 0.17, 'agi' => 0.68, 'con' => 0.15 },
  'specter'      => { 'str' => 0.20, 'agi' => 0.65, 'con' => 0.15 },
  'mirage'       => { 'str' => 0.22, 'agi' => 0.63, 'con' => 0.15 },
  'blur'         => { 'str' => 0.20, 'agi' => 0.67, 'con' => 0.13 },
  'ghost'        => { 'str' => 0.18, 'agi' => 0.70, 'con' => 0.12 },
  'evader'       => { 'str' => 0.22, 'agi' => 0.65, 'con' => 0.13 },
  'dodge_master' => { 'str' => 0.20, 'agi' => 0.68, 'con' => 0.12 },
  'illusionist'  => { 'str' => 0.18, 'agi' => 0.67, 'con' => 0.15 },
  # Bruiser-type: high STR, low AGI, high CON
  'crusader'     => { 'str' => 0.50, 'agi' => 0.08, 'con' => 0.42 },
  'templar'      => { 'str' => 0.48, 'agi' => 0.10, 'con' => 0.42 },
  'knight'       => { 'str' => 0.45, 'agi' => 0.12, 'con' => 0.43 },
  'champion'     => { 'str' => 0.50, 'agi' => 0.10, 'con' => 0.40 },
  'vanguard'     => { 'str' => 0.48, 'agi' => 0.08, 'con' => 0.44 },
  'oath_keeper'  => { 'str' => 0.45, 'agi' => 0.10, 'con' => 0.45 },
  'iron_warrior' => { 'str' => 0.52, 'agi' => 0.08, 'con' => 0.40 },
  'heavy_guard'  => { 'str' => 0.48, 'agi' => 0.12, 'con' => 0.40 },
  'steel_wall'   => { 'str' => 0.50, 'agi' => 0.05, 'con' => 0.45 },
  'bulwark_lord' => { 'str' => 0.48, 'agi' => 0.07, 'con' => 0.45 },
  # Skirmisher-type: balanced STR+AGI, low CON
  'duelist'      => { 'str' => 0.40, 'agi' => 0.40, 'con' => 0.20 },
  'fencer'       => { 'str' => 0.38, 'agi' => 0.42, 'con' => 0.20 },
  'ranger'       => { 'str' => 0.40, 'agi' => 0.38, 'con' => 0.22 },
  'skirmisher'   => { 'str' => 0.42, 'agi' => 0.38, 'con' => 0.20 },
  'corsair'      => { 'str' => 0.38, 'agi' => 0.40, 'con' => 0.22 },
  'hunter'       => { 'str' => 0.42, 'agi' => 0.35, 'con' => 0.23 },
  'predator'     => { 'str' => 0.45, 'agi' => 0.35, 'con' => 0.20 },
  'stalker'      => { 'str' => 0.40, 'agi' => 0.40, 'con' => 0.20 },
  'swashbuckler' => { 'str' => 0.38, 'agi' => 0.42, 'con' => 0.20 },
  'blade_dancer' => { 'str' => 0.42, 'agi' => 0.40, 'con' => 0.18 },
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

def generate_player_character(archetype_name)
  weights = PLAYER_ARCHETYPES[archetype_name]
  raise "Unknown player archetype: #{archetype_name}" unless weights
  stats = allocate_points(weights, RULES['player_points'])
  make_character(str: stats['str'], agi: stats['agi'], con: stats['con'])
end

def generate_opponent_character(archetype_name)
  arch = OPPONENTS[archetype_name]
  raise "Unknown opponent: #{archetype_name}" unless arch
  stats = allocate_points(arch['weights'], RULES['opponent_points'])
  make_character(str: stats['str'], agi: stats['agi'], con: stats['con'])
end

def tournament(char_a, seed: 42)
  opponents = OPPONENTS.keys.map { |name| generate_opponent_character(name) }
  rng = Random.new(seed)
  bracket = opponents.shuffle(random: rng)
  a_hp = char_a[:hp].to_f
  fights = []
  bracket.each do |opp|
    b_hp = opp[:hp].to_f
    rounds = 0
    while a_hp > 0 && b_hp > 0 && rounds < MAX_ROUNDS
      rounds += 1
      a_takes = [opp[:str] - char_a[:dr] + rng.rand(-1..1), 0].max
      b_takes = [char_a[:str] - opp[:dr] + rng.rand(-1..1), 0].max
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

def simulate_tournament(char_a, seeds: (1..100).to_a)
  results = seeds.map { |s| tournament(char_a, seed: s) }
  wins = results.count { |r| r[:winner] == 'player' }
  { simulations: seeds.size, wins: wins, win_pct: (wins.to_f / seeds.size * 100).round(1) }
end

if __FILE__ == $0
  if ARGV.include?('--archetype')
    name = ARGV[ARGV.index('--archetype') + 1]
    char_a = generate_player_character(name)
    if ARGV.include?('--simulate')
      puts JSON.pretty_generate(simulate_tournament(char_a))
    else
      seed = ARGV.reject { |x| ['--archetype', '--tournament', '--simulate', name].include?(x) }.first&.to_i || 42
      puts JSON.pretty_generate(tournament(char_a, seed: seed))
    end
  elsif ARGV.length >= 6
    a = make_character(str: ARGV[0].to_i, agi: ARGV[1].to_i, con: ARGV[2].to_i)
    b = make_character(str: ARGV[3].to_i, agi: ARGV[4].to_i, con: ARGV[5].to_i)
    seed = ARGV[6]&.to_i || 42
    puts JSON.pretty_generate(battle(a, b, seed: seed))
  else
    puts "Usage:"
    puts "  ruby battle.rb --archetype NAME --tournament [seed]"
    puts "  ruby battle.rb --archetype NAME --tournament --simulate"
    exit 1
  end
end
