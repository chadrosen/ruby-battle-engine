# Ruby Battle Engine

A turn-based battle simulator for character-building challenges.

## Stats

- **Strength (STR)** — damage dealt per round
- **Agility (AGI)** — damage reduction (0.5 per point)
- **Constitution (CON)** — hit points (20 per point)

## Mechanics

- Both characters attack simultaneously each round
- Damage = attacker STR − defender AGI×0.5 ± 1 (random variance, min 0 per hit)
- First to 0 HP loses; if simultaneous, higher remaining HP wins
- Battle ends after 300 rounds (compare remaining HP)

## Tournament Mode

A tournament runs the player character through a bracket of opponents. The bracket
order is **randomized by seed** — different seeds produce different opponent orderings,
meaning the player might face the hardest opponent first or last.

**Rules:**
- Level N tournament uses the first N opponents sorted by level (level 1 through N)
- Bracket order is shuffled randomly using the seed as the RNG source
- **HP carries over** between fights — remaining HP after fight 1 becomes starting HP for fight 2
- The player must **win every fight** to win the tournament
- If the player loses any fight, the tournament ends and they lose

**Why HP carry-over matters:**  
A build that barely survives the Berserker (high STR opponent) enters the next fight
heavily damaged. A build with higher CON or AGI may take less damage in early fights
and arrive at later fights in better shape. Pure STR builds that win fast are
sometimes safer than tanky builds that win slow.

**Why random bracket order matters:**  
The Iron Golem (high AGI, DR=4) deals very little damage, so facing it first is a
"free" fight. Facing the Berserker (STR=12) first is brutal. A good build must
survive the worst-case ordering, not just a favorable one. Win rate across 100 seeds
measures how reliably the build handles random orderings.

## Leveling

Characters gain points per level. Each stat must be at least 1.

| Level | Total points | Formula |
|-------|-------------|---------|
| 1 | 13 | 3 + 10×1 |
| 2 | 23 | 3 + 10×2 |
| 3 | 33 | 3 + 10×3 |
| 4 | 43 | 3 + 10×4 |

## Usage

```bash
# Single battle (two explicit characters)
ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> [seed]

# Simulate 100 single battles
ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> --simulate

# Single tournament run at level N (default seed 42)
ruby battle.rb <str_a> <agi_a> <con_a> --tournament --level N [seed]

# Simulate 100 tournament seeds at level N
ruby battle.rb <str_a> <agi_a> <con_a> --tournament --level N --simulate
```

### Tournament output example

```bash
ruby battle.rb 14 6 13 --tournament --level 3 --simulate
```

```json
{
  "simulations": 100,
  "level": 3,
  "wins": 72,
  "win_pct": 72.0,
  "avg_fights_completed": 2.8
}
```

### Single tournament run output

```bash
ruby battle.rb 14 6 13 --tournament --level 3 42
```

```json
{
  "winner": "a",
  "fights_completed": 3,
  "final_a_hp": 45.0,
  "fights": [
    { "opponent": 2, "winner": "a", "a_hp_after": 120.0, "rounds": 10 },
    { "opponent": 1, "winner": "a", "a_hp_after": 118.0, "rounds": 2 },
    { "opponent": 3, "winner": "a", "a_hp_after": 45.0, "rounds": 8 }
  ]
}
```

Note: `opponent` in fights refers to the opponent's level number.

## Opponents (characters.json)

| Name | Level | STR | AGI | CON | HP | DR | Notes |
|------|-------|-----|-----|-----|----|----|-------|
| Goblin | 1 | 3 | 1 | 4 | 80 | 0.5 | Weak; good warm-up |
| Iron Golem | 2 | 5 | 8 | 4 | 80 | 4.0 | Very high DR — player needs STR > 5 to deal net damage |
| Berserker | 3 | 12 | 2 | 6 | 120 | 1.0 | Massive damage output; biggest threat to low-CON builds |
| Champion | 4 | 9 | 5 | 10 | 200 | 2.5 | High HP; long fight drains carry-over HP |
