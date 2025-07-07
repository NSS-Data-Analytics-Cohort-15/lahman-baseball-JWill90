-- 1. What range of years for baseball games played does the provided database cover? 

SELECT
    MIN(yearid) AS earliest_year,
    MAX(yearid) AS latest_year
FROM teams;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT 
	CONCAT(p.namefirst, ' ', p.namelast) AS name, 
	a. teamid,
	a.g_all AS total_games_played,	
	MIN(p.height) AS shortest_height
FROM people AS p
INNER JOIN appearances AS a
USING (playerid)
GROUP BY p.namefirst, p.namelast, a.teamid, a.g_all, p.height
ORDER BY p.height
LIMIT 1; 

-- SLA: Team Name: St. Louis Browns
	

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT	
	DISTINCT(c.playerid),
	CONCAT(p.namefirst, ' ', p.namelast) AS player_name,
	SUM(s.salary::INT::MONEY) AS total_salary
FROM people AS p
	INNER JOIN (SELECT DISTINCT(playerid)
	FROM collegeplaying
	WHERE schoolid = 'vandy') AS c
	USING(playerid)
INNER JOIN salaries AS s
USING(playerid)
GROUP BY c.playerid, p.namefirst, p.namelast
ORDER BY total_salary DESC;


-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT 
	CASE
		WHEN pos = 'OF' THEN 'outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'infield'
		WHEN pos IN ('P', 'C') THEN 'battery'
		ELSE 'other'
	END AS player_position,
	SUM(po) AS total_putouts
FROM fielding 
WHERE yearid = '2016'
GROUP BY player_position
ORDER BY total_putouts DESC;

   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT
    (yearid / 10) * 10 AS decade, -- Created for each decade
    ROUND(SUM(so) / 1.0 / SUM(g), 2) AS avg_strikeouts_per_game, -- Using (1.0) in order to cast to decimal 
    ROUND(SUM(hr) / 1.0 / SUM(g), 2) AS avg_homeruns_per_game    -- Using (1.0) in order to cast to decimal 
FROM
    teams 
WHERE
    yearid >= 1920
GROUP BY
   decade
ORDER BY
    decade;


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT
    CONCAT(p.namefirst, ' ', p.namelast) AS player_name,
    b.sb AS stolen_bases,
    b.cs AS caught_stealing,
    (b.sb + b.cs) AS total_attempts,
    ROUND(CAST(b.sb AS DECIMAL) / (b.sb + b.cs) * 100, 2) AS success_percentage -- This is calculating the percentage
FROM batting AS b 
INNER JOIN people AS p
USING (playerid)
WHERE b.yearid = 2016 
    AND b.sb IS NOT NULL -- Using to ensure sb data exists
    AND b.cs IS NOT NULL --  Using to ensure cs data exists
    AND (b.sb + b.cs) >= 20 -- Using to filter for players with at least 20 attempts
ORDER BY success_percentage DESC, total_attempts DESC 
LIMIT 1;


-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

-- Part 1 

SELECT
    MAX(t.w) AS largest_wins_non_ws_winner,
(
	SELECT
	    MIN(w) AS smallest_wins_ws_winner
		FROM teams AS t
		WHERE wswin = 'Y'
				)
FROM teams AS t
WHERE t.wswin = 'N'
    AND t.yearid BETWEEN 1970 AND 2016;

-- Part 2

-- Determining why there's an unusually small number of wins for a world series champion/Assessing the problem year (Excluded the lowest in 1981). After researching; From June 12 to August 8, 1981, MLB players went on strike due to a labor dispute over free agent compensation. This resulted in the cancellation of 712 regular season games and their performance had been shortened and fragmented for the season. Their "total wins" for the year would reflect only the games they played, which was a much smaller number than in a typical full season.


-- Use to determine which year had the lowest amount of wins

SELECT *
FROM teams AS t 
WHERE t.wswin = 'Y'
    AND t.yearid BETWEEN 1970 AND 2016
ORDER BY t.w

-- Excluding 1981 -- 

SELECT
    MAX(t.w) AS largest_wins_non_ws_winner,
(
	SELECT
	    MIN(w) AS smallest_wins_ws_winner
		FROM teams AS t
		WHERE wswin = 'Y'
			
	)
FROM teams AS t
WHERE t.wswin = 'N'
    AND t.yearid BETWEEN 1970 AND 2016
	AND t.yearid != 1981

-- Obtained the same results as in Part 1 after attempting to filter out 1981

-- Part 3 -- 

WITH yr_max_wins AS (
    -- maximum wins for each year from 1970-2016
    SELECT
        yearid,
        MAX(w) AS max_wins_in_year
    FROM teams AS t
    WHERE yearid BETWEEN 1970 AND 2016
    GROUP BY yearid
),
yr_max_wins_ws AS (
    -- number of years where a team with max wins also won the world series 
    SELECT
        COUNT(DISTINCT t.yearid) AS count_max_wins_won_ws
    FROM teams AS t
    INNER JOIN yr_max_wins AS ymw 
	ON t.yearid = ymw.yearid 
		AND t.w = ymw.max_wins_in_year
    WHERE t.wswin = 'Y'
),
total_years AS (
    -- total number of years in the range
    SELECT
        COUNT(DISTINCT yearid) AS total_year_count
    FROM teams
    WHERE yearid BETWEEN 1970 AND 2016
		AND yearid != 1981
)
SELECT
    ymws.count_max_wins_won_ws AS num_times_max_wins_won_ws,
    ty.total_year_count,
    ROUND(CAST(ymws.count_max_wins_won_ws AS DECIMAL) * 100.0 / ty.total_year_count, 2) AS percentage_max_wins_won_ws
FROM yr_max_wins_ws AS ymws, total_years AS ty;

-- From 1970 – 2016, what was the case that a team with the most wins also won the world series? What percentage of the time?
-- Number of max wins: 12 Total Yr. Count: 46 Percentage of max wins: 26.09%


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


SELECT *
FROM homegames;

SELECT 
	team, 
	park,
	SUM(attendance) / SUM(games) AS avg_attendance_per_game
FROM homegames
WHERE year = 2016 
	AND games >= 10
GROUP BY team, park
ORDER BY avg_attendance_per_game DESC
LIMIT 5;

-- Adding team name --- 

SELECT
    t.name AS team_name,        
    p.park_name,               
   	SUM(h.attendance) / SUM(h.games) AS avg_attendance_per_game
FROM homegames AS h
INNER JOIN teams AS t 
ON h.team = t.teamid  
	AND h.year = t.yearid
INNER JOIN parks AS p 
ON h.park = p.park  
WHERE h.year = 2016
    AND h.games >= 10
GROUP BY t.name, p.park_name 
ORDER BY avg_attendance_per_game DESC
LIMIT 5;


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT *
FROM awardsmanagers;

SELECT * 
FROM managers;


-- Initial Query 

SELECT 
	playerid AS manager,
	m.awardid,
	m.yearid,
	m.lgid,
	t.teamid
FROM awardsmanagers AS m
LEFT JOIN 
	teams AS t
ON m.lgid = t.lgid -- lgid in the teams table could reflect the league of the player not manager (DD didn't spec)
WHERE m.awardid = 'TSN Manager of the Year'
	AND m.lgid IN ('NL', 'AL')
GROUP BY playerid, m.awardid, m.yearid, m.lgid, t.teamid
ORDER BY m.yearid DESC;


-- Modified Query using sub (Extracting data using 4 tables)

SELECT
    am.yearid,
    am.lgid,
	p.namefirst,
    p.namelast,    
    t.name AS teamname 
FROM
    awardsmanagers AS am
INNER JOIN
    people AS p 
	ON am.playerid = p.playerid
INNER JOIN
    managers AS m ON am.playerid = m.playerid
                  AND am.yearid = m.yearid
                  AND am.lgid = m.lgid 
INNER JOIN
    teams AS t ON m.teamid = t.teamid
                AND m.yearid = t.yearid
                AND m.lgid = t.lgid
WHERE
    am.awardid = 'TSN Manager of the Year'
    AND am.lgid IN ('NL', 'AL')
    AND am.playerid IN ( -- Using a subquery to filter for the managers who won in both leagues
        SELECT playerid
        FROM awardsmanagers
        WHERE awardid = 'TSN Manager of the Year'
        AND lgid IN ('NL', 'AL')
        GROUP BY playerid
        HAVING COUNT(DISTINCT lgid) = 2 -- To filter awards for both NL and AL
    )
ORDER BY
    p.namelast, p.namefirst, am.yearid;

-- Researched names in query to verify that they were indeed coaches vs players 

-- CTE Created 

WITH bl AS (
    SELECT
        playerid
    FROM
        awardsmanagers
    WHERE
        awardid = 'TSN Manager of the Year'
        AND lgid IN ('NL', 'AL')
    GROUP BY
        playerid  
    HAVING
        COUNT(DISTINCT lgid) = 2 -- includes filters for both NL and AL
)
SELECT
    p.namefirst,
    p.namelast,
    am.yearid,
    am.lgid,
    t.name AS teamname
FROM
    awardsmanagers AS am
INNER JOIN
    people AS p 
	ON am.playerid = p.playerid
INNER JOIN
    managers AS m ON am.playerid = m.playerid
                  AND am.yearid = m.yearid
                  AND am.lgid = m.lgid
INNER JOIN teams AS t 
ON m.teamid = t.teamid
                AND m.yearid = t.yearid
                AND m.lgid = t.lgid
INNER JOIN --  Adding an additional inner join referencing my CTE to filter for managers who are in both leagues
    bl ON am.playerid = bl.playerid
WHERE
    am.awardID = 'TSN Manager of the Year'
    AND am.lgid IN ('NL', 'AL')
ORDER BY
    p.namelast, p.namefirst, am.yearid;

-- CTE Query For Reuse

WITH bl AS (
    SELECT
        playerID
    FROM
        awardsmanagers
    WHERE
        awardID = 'TSN Manager of the Year'
        AND lgID IN ('NL', 'AL')
    GROUP BY
        playerID
    HAVING
        COUNT(DISTINCT lgID) = 2
)
SELECT *
FROM bl;


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- Using (3) CTEs to answer the above question: 

WITH playerchr AS (
    -- career-high home runs for each player across all years
    SELECT
        playerid,
        MAX(hr) AS career_max_hr
    FROM batting
    GROUP BY playerid
),
hr_2016 AS (
    -- total home runs for each player in 2016 (if they hit at least one)
    SELECT
        playerid,
        SUM(hr) AS hr_2016
    FROM batting
    WHERE yearid = 2016 
    GROUP BY playerid
    HAVING SUM(hr) >= 1
),
player_years AS (
    -- the number of years each player has played
    SELECT
        playerid,
        COUNT(DISTINCT yearid) AS years_played
    FROM batting
    GROUP BY playerid
    HAVING COUNT(DISTINCT yearid) >= 10 
)
	SELECT
	    CONCAT(p.namefirst, ' ', p.namelast) AS player_name,
	    h2016.hr_2016
	FROM people AS p
	INNER JOIN hr_2016 AS h2016 
	ON p.playerid = h2016.playerid
	INNER JOIN playerchr AS pchr 
	ON p.playerid = pchr.playerid
	INNER JOIN player_years AS py 
	ON p.playerid = py.playerid -- Join condition using the third CTE for years played
	WHERE  h2016.hr_2016 = pchr.career_max_hr -- using to filter players where home runs hit in 2016 are equal to the highest number of home runs during players career 
	ORDER BY  h2016.hr_2016 DESC;


-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

SELECT
    t.yearid,
    t.name AS team_name,
   	t.w AS team_wins,
    SUM(s.salary::INT::MONEY) AS total_team_salary
FROM
    teams AS t
INNER JOIN salaries AS s 
ON t.teamid = s.teamid 
	AND t.yearid = s.yearid 
WHERE t.yearid >= '2000'
GROUP BY t.yearid, t.name, t.w 
ORDER BY t.yearid, team_wins DESC;

-- For Chart 

WITH decades AS (
	SELECT
		generate_series(1920, 2020, 10) AS decade_start
	)
SELECT
    decade_start::text || 's' AS decade,
	t.name AS team_name,
   	MAX(t.w) AS team_wins,
    SUM(s.salary::INT::MONEY) AS total_team_salary
FROM teams AS t
INNER JOIN salaries AS s 
ON t.teamid = s.teamid 
	AND t.yearid = s.yearid 
INNER JOIN decades 
ON s.yearid BETWEEN decade_start 
	AND decade_start + 80
WHERE t.yearid >= '2000'
GROUP BY decade_start, t.name
ORDER BY decade_start, total_team_salary DESC;

-- The correlation between team salary and wins suggests a team strategy of investing in top-tier players to maximize the likelihood of achieving a higher overall win count.

-- 12. In this question, you will explore the connection between number of wins and attendance. *  Does there appear to be any correlation between attendance at home games and number of wins? </li> *  Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.


-- Part 1 -- 
SELECT
    t.yearid,
    t.name AS team_name,
    t.w AS total_wins,
    t.attendance AS total_attendance 
FROM
    teams AS t
WHERE t.yearid >= 2000 
	-- AND t.name = 'New York Yankees'
ORDER BY t.yearid, t.name;

-- There does not appear to be any correlation between attendance at home games and number of wins.

-- Part 2 -- Using a self-join to best answer this question 

SELECT
    current_year.yearid AS year_of_success,
    current_year.name AS team_name,
    current_year.w AS current_year_wins,
    current_year.attendance AS attendance_in_success_year,
    next_year.attendance AS attendance_in_following_year,
    (next_year.attendance - current_year.attendance) AS attendance_change,
    ROUND(((next_year.attendance - current_year.attendance) * 1.0 / current_year.attendance) * 100, 2) AS attendance_change_percent,
    'World Series Winner' AS success_category
FROM teams AS current_year
INNER JOIN teams AS next_year
    ON current_year.teamid = next_year.teamid 
	AND current_year.yearid = next_year.yearid - 1
WHERE current_year.yearid >= 2000 
    AND current_year.wswin = 'Y' 
    AND current_year.attendance IS NOT NULL 
    AND next_year.attendance IS NOT NULL 
UNION ALL
SELECT
    current_year.yearid AS year_of_success,
    current_year.name AS team_name,
    current_year.w AS current_year_wins,
    current_year.attendance AS attendance_in_success_year,
    next_year.attendance AS attendance_in_following_year,
    (next_year.attendance - current_year.attendance) AS attendance_change,
    ROUND(((next_year.attendance - current_year.attendance) * 1.0 / current_year.attendance) * 100, 2) AS attendance_change_percent,
    'Other Playoff Team' AS success_category
FROM teams AS current_year
INNER JOIN teams AS next_year
    ON current_year.teamid = next_year.teamid 
	AND current_year.yearid = next_year.yearid - 1
WHERE current_year.yearid >= 2000 
    AND (current_year.divwin = 'Y' OR current_year.wcwin = 'Y') 
    AND current_year.wswin = 'N' 
    AND current_year.attendance IS NOT NULL
    AND next_year.attendance IS NOT NULL
ORDER BY year_of_success, success_category, attendance_change_percent DESC;


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?


SELECT * 
FROM AwardsSharePlayers 
WHERE awardid = 'Cy Young'

-- Original queries -- 

SELECT 
	COUNT(CASE WHEN bats = 'L' THEN 'left' 
		END) AS left_handed,
	COUNT(CASE WHEN bats = 'R' THEN 'right'
		END) AS right_handed,
		ELSE 'Other' END AS batting_hand
FROM people
INNER JOIN awardsshareplayers
USING(playerid)
INNER JOIN halloffame
USING(playerid)
WHERE awardid = 'Cy Young' 
-- WHERE throws = 'L'
	-- AND awardid = 'Cy Young' 
-- 3654 -- / 1323 / win Cy Young Award 339 (0.09)/ win hallof fame 2903 (79% like to make it to the hall of fame)


SELECT 
	throws
FROM people
INNER JOIN awardsshareplayers
USING(playerid)
INNER JOIN halloffame
USING(playerid)
WHERE throws = 'R'
	AND awardid = 'Cy Young' -- 14480 -- / 5556 /win Cy Young Award 905 (0.06)/ win halloffame 14855 (97% like to make it to the hall of fame)


-- Using Case Statement to answer question -- 

SELECT
    COUNT(CASE WHEN throws = 'L' THEN 1 END) AS left_handed,
    COUNT(CASE WHEN throws = 'R' THEN 1 END) AS right_handed,
    COUNT(CASE WHEN throws NOT IN ('L', 'R') THEN 1 END) AS other 
FROM people AS p -- left_handed (3654) right_handed (14480)	other (1) 
INNER JOIN awardsshareplayers AS asp 
USING(playerid)
INNER JOIN halloffame AS hof 
USING(playerid) 
WHERE asp.awardid = 'Cy Young';
-- left_handed (339) right_handed (905) other (0)

-- left_handed pitchers make up approximately 20.15% of the general pitching population in the dataset, they make up approximately 27.25% of the Cy Young Award winners leading to left-handed players having a higher probability of winning both awards


