--General query to see if everything comes up alright in CovidDeaths table
SELECT *
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY 3, 4;

--General query to see if everything comes up alright in CovidVaccinations table
SELECT *
  FROM PortfolioProject..CovidVaccinations
 WHERE continent IS NOT NULL
 ORDER BY 3, 4;

--Selecting data that I am going to use for this example
SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY 1, 2;

--Looking at the total cases vs total deaths (% of people who had COVID that died)
--Shows the likelihood of a person dying if they contract COVID in their country, example country is US
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS Death_Percentage
  FROM PortfolioProject..CovidDeaths
 WHERE location like '%states%'
   AND continent IS NOT NULL
 ORDER BY 1, 2;

--Looking at total cases vs population
--Shows what percentage of the population has gotten COVID in the US
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS Percent_Population_Infected
  FROM PortfolioProject..CovidDeaths
 WHERE location like '%states%'
   AND continent IS NOT NULL
 ORDER BY 1, 2;

--Looking at countries with the highest infection rate compared to population
SELECT location, MAX(total_cases) AS Highest_Infection_Count, population, MAX((total_cases/population)) * 100 AS Percent_Population_Infected
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY location, population
 ORDER BY Percent_Population_Infected DESC;

--Showing countries with the highest death count per population
SELECT location, MAX(cast(total_deaths AS INT)) AS Total_Death_Count
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY location
 ORDER BY Total_Death_Count DESC;

--Breaking things down by continent
SELECT continent, MAX(cast(total_deaths AS INT)) AS Total_Death_Count
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY continent
 ORDER BY Total_Death_Count DESC;

--Showing the continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths AS INT)) AS Total_Death_Count
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY continent
 ORDER BY Total_Death_Count DESC;

--Global numbers for everything by date
SELECT date, SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths AS INT)) AS Total_Deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) * 100 AS Death_Percentage
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY date
 ORDER BY 1, 2;

--Global number for everything total
SELECT SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths AS INT)) AS Total_Deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) * 100 AS Death_Percentage
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY 1, 2;

--Looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  FROM PortfolioProject..CovidDeaths dea
  JOIN PortfolioProject..CovidVaccinations vac
       ON dea.location  = vac.location
       AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 ORDER BY 2, 3;

--Looking at new vaccinations on a rolling basis. Note: I tried using (SUM(convert..'INT,vac...' it didnt work cause the integer was too big, replaced it with 'bigint, vac...' and it worked.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
  FROM PortfolioProject..CovidDeaths dea
  JOIN PortfolioProject..CovidVaccinations vac
	   ON dea.location  = vac.location
	   AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 ORDER BY 2, 3;

--Using CTE to look at new vaccinations on a rolling basis and calculate the highest number of people vaccinated (highest value for rolling_people_vaccinated/population)
WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
  FROM PortfolioProject..CovidDeaths dea
  JOIN PortfolioProject..CovidVaccinations vac
	   ON dea.location  = vac.location
	   AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
)
SELECT *, (Rolling_People_Vaccinated/Population) * 100
  FROM PopvsVac;

--Using TEMP TABLE to look at new vaccinations on a rolling basis and calculate the highest number of people vaccinated (highest value for rolling_people_vaccinated/population)
DROP TABLE IF EXISTS #Percent_Population_Vaccinated
CREATE TABLE #Percent_Population_Vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
  FROM PortfolioProject..CovidDeaths dea
  JOIN PortfolioProject..CovidVaccinations vac
	   ON dea.location  = vac.location
	   AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL

SELECT *, (Rolling_People_Vaccinated/Population) * 100
  FROM #Percent_Population_Vaccinated

--Creating view to store data for later visualizations
CREATE VIEW Percent_Population_Vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) AS Rolling_People_Vaccinated
  FROM PortfolioProject..CovidDeaths dea
  JOIN PortfolioProject..CovidVaccinations vac
	   ON dea.location  = vac.location
	   AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL

--After creating a view: go to the list on left, click Views > System Views, open the new view with Show Top 1000 Rows in its own query window then go back and right click it from list on the left and hit refresh so it loads, after that you can query directly from the view

--Querying from view
SELECT *
  FROM Percent_Population_Vaccinated
