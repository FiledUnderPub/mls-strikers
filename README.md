# Filed Under: MLS strikers

*Notes from the field. Charts from the wild.*

**Full post:** [filedunderpub.substack.com/p/POST-SLUG](https://filedunderpub.substack.com/p/POST-SLUG)

---

## The finding

Of 55 MLS strikers with 900 or more regular-season minutes in 2025, one scored
non-penalty goals at a rate outside the range expected by chance: Lionel Messi,
0.93 per 90 against a pooled rate of 0.37. His 28 non-penalty goals were nine
more than any other player at any position.

---

## What's in this repo

| File | Contents |
|---|---|
| `data-prep.R` | Pulls 2025 regular-season player data from the American Soccer Analysis API and writes the analysis file |
| `data/mls-teams-2025.csv` | American Soccer Analysis, MLS 2025 regular season, one row per team: points, goals, xG, penalties |
| `data/mls-attackers-2025.csv` | American Soccer Analysis, MLS 2025 regular season, one row per striker, winger, and attacking midfielder |
| `analysis.Rmd` | Completeness filtering, striker definition, overall and conference top tens, East–West and age tests, elastic-net model of over- and underperformance, and observations |
| `output/mls-strikers.png` | The published chart: funnel plot of non-penalty goals per 90 against minutes played |
| `output/mls-strikers-per90.png` | Supporting chart: non-penalty goals vs. xG per 90, East, West, and overall top tens |

The visual theme is proprietary and not included. Anyone running `analysis.Rmd`
can reproduce the data and statistical findings; the chart styling is not part of
this repository.

---

## Data source

American Soccer Analysis. *ASA API v1: MLS player xGoals and Goals Added, 2025
Regular Season.* https://app.americansocceranalysis.com/api/v1/

Accessed at https://app.americansocceranalysis.com/api/v1/mls on 25 September 2026.

- `season_name = 2025`, `stage_name = Regular Season` (510 matches, 22 February – 18 October 2025)
- `/players/xgoals`: all shots, and penalties only (`shot_pattern = Penalty`)
- `/players/xgoals` split by team, to assign each player a primary team
- `/players/goals-added`, `/players`, `/teams`
- `/teams/xgoals`: all shots, and penalties only

---

## Methodology notes

**Striker definition.** A striker is a player whose most common position in
2025 was `ST` in ASA's classification. Several leading scorers are classified
as wingers or attacking midfielders (Dénis Bouanga, Anders Dreyer, Evander) and
are excluded from the striker rankings. They are listed in `analysis.Rmd`. No
player outside the striker, winger, and attacking-midfielder positions scored
more than 9 non-penalty goals.

**Minutes threshold.** Rankings and tests use strikers with at least 900
minutes (n = 55; 28 East, 27 West). No striker below the threshold reached the
top ten.

**Penalties.** Non-penalty goals (npG) and non-penalty xG (npxG) subtract
penalty kicks, which are assigned by the team rather than earned in open play.
Top-ten tables rank by total goals, with MLS Golden Boot tiebreakers (assists,
then fewer minutes). The chart ranks by non-penalty goals.

**Conference.** Players who appeared for two teams are assigned to the team
where they played more minutes, and that team's 2025 conference.

**East vs. West.** Two-sided Wilcoxon rank-sum tests on eight per-player
measures (goals, non-penalty goals, non-penalty xG, and non-penalty shots per
90; xG per shot; conversion; shots-on-target rate; npG minus npxG per 90),
Benjamini–Hochberg-adjusted, with effect size r. No measure differed between
conferences (all p.adj ≥ 0.32; all effects small).

**Individual strikers.** Two methods. Descriptive: 1.5× / 3× IQR outliers on
each measure, league-wide and within each conference. Inferential: exact
two-sided Poisson tests of each striker's non-penalty goals per 90 against the
pooled rate of all other qualifying strikers, league-wide and within the
conference, and of non-penalty goals against the striker's own npxG (reference
ratio: the striker pool's 0.90). BH-adjusted across the 55 strikers. Only
Lionel Messi differs significantly from the league and from his conference
(p.adj < 0.001 for each). No striker differs significantly from his own xG.

**Predictors of over- and underperformance.** Outcome: non-penalty goals per
90 above (1) or below (0) non-penalty xG per 90, among strikers, wingers, and
attacking midfielders with 900+ minutes (n = 153; 59 above). Elastic-net
logistic regression (`glmnet`, α = 0.5, λ by 5-fold CV) on standardised
predictors: age, minutes, conference, multi-team status, non-penalty shots per
90, xG per shot, shots-on-target rate, penalty attempts per 90, key passes,
assists, and xA per 90, and position. Variables that contain the outcome
(goals, conversion rate, g+) are excluded. Performance is nested-CV AUC,
compared with 100 permutations of the outcome. Predictor stability is the
share of 200 bootstrap resamples retaining each predictor. Shots-on-target rate
is partly the outcome restated, so models are reported with and without it.
Among strikers alone (n = 55), no model without shots-on-target rate beat
shuffled labels.

**Team context.** Whether a striker scored more than his team's performance
predicts, under two definitions: the rest of the team's non-penalty xG per
game (the striker's own npxG subtracted), and team points per game. Negative
binomial regression of non-penalty goals on each, offset by log(90-minute
units); each striker's expected total from a leave-one-out fit; two-sided
exact negative binomial test, BH-adjusted. Strikers who played for two teams
(3) are excluded. Only Messi scored significantly above expectation (p.adj =
0.001 and 0.015). Share of team non-penalty goals is reported descriptively.

**Funnel plot.** The published chart plots each striker's non-penalty goals
per 90 against minutes played, with exact Poisson 95% and 99.8% control
limits around the pooled striker rate (0.37 per 90), smoothed between integer
counts (Spiegelhalter 2005). The limits are not adjusted for multiple
comparisons; the BH-adjusted rate tests are the formal result.

**Expected goals in 2025.** League-wide, 2025 produced 1,355 non-penalty goals
from 1,519 non-penalty xG (ratio 0.89), against 0.94–1.03 in 2019 and 2021–2024.
The data does not distinguish between lower finishing and a shift in the shot
model. The published finding uses goal counts only.

Full code and annotated output are in `analysis.Rmd`.

---

*Filed Under. Observed in the wild.*
