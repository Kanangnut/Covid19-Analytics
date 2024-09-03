select *
from covid19_db..CovidDeaths
where continent is not null
order by 3,4

select *
from covid19_db..CovidDeaths
order by 3,4

--select Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from covid19_db..CovidDeaths
order by 1,2

--looking at Total Cases vs Total Deaths 
--show likelihood of dying if you contract covid in USA
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from covid19_db..CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2 

--looking at Total Cases vs Total Deaths 
--show likelihood of dying if you contract covid in Thailand
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from covid19_db..CovidDeaths
where location like '%Thailand%'
and continent is not null
order by 1,2 

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
select location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from covid19_db..CovidDeaths
order by 1, 2

--select Location, date, population, total_cases,
--case when total_cases = 0 then 0
--else (total_deaths/total_cases) * 100 end as DeathPercentage
--from covid19_db..CovidDeaths
----where location like '%Thailand%'
--order by 1,2 

--Looking at COuntries with Highest Infection Rate compared to Population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from covid19_db..CovidDeaths
--where location like '%Thailand%'
group by location, population
order by PercentPopulationInfected desc

--Showing Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM covid19_db..CovidDeaths
--WHERE location LIKE '%Thailand%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Let's break things down by continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM covid19_db..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--Showing continent with highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM covid19_db..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global numbers
select SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from covid19_db..CovidDeaths
--where location like '%Thailand%'
where continent is not null
--group by date
order by 1,2

--Looking at Total population vs Vaccinations 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from covid19_db..CovidDeaths dea
join covid19_db..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--USE CTE
with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from covid19_db..CovidDeaths dea
join covid19_db..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac

--TEMP TABLE
DROP table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from covid19_db..CovidDeaths dea
join covid19_db..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


--Creating view to store data for later visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    -- , (SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / population) * 100 AS PercentPopulationVaccinated
FROM 
    covid19_db..CovidDeaths dea
JOIN 
    covid19_db..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;


select *
from PercentPopulationVaccinated 


--For Tableau Public
--1. Table 1
select SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from covid19_db..CovidDeaths
--where location like '%Thailand%'
where continent is not null
--group by date
order by 1,2


--2.
--We take these out as they are not included in the above qyeries and want to stay consisitent
-- European Union is part of Europe
select location, SUM(cast(new_deaths as int)) as TotalDeathCount
from covid19_db..CovidDeaths
--where location like '%states%'
where continent is null
and location not in ('world', 'european union', 'international')
group by location
order by TotalDeathCount desc

--3
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from covid19_db..CovidDeaths
--where location like '%states%'
group by location, population
order by PercentPopulationInfected desc

--4
select location, Population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from covid19_db..CovidDeaths
--where location like '%states%'
group by location, population, date
order by PercentPopulationInfected desc


--Vaccinations
select *
from covid19_db..CovidVaccinations 

--1. Percentage Fully Vaccinated
SELECT 
    v.location AS Country,
    YEAR(v.date) AS Year,
    MAX(v.people_fully_vaccinated) AS Total_Fully_Vaccinated,
    MAX((v.people_fully_vaccinated / d.population) * 100) AS Percentage_Fully_Vaccinated
FROM 
    covid19_db..CovidVaccinations v
JOIN 
    covid19_db..CovidDeaths d ON v.location = d.location
GROUP BY 
    v.location, YEAR(v.date)
HAVING 
    MAX(v.people_fully_vaccinated) > 0
ORDER BY 
    Country, Year;


--Top 5 Countries with the Highest Vaccination Rate per 100 People
SELECT TOP 5
    location AS Country,
    MAX(total_vaccinations_per_hundred) AS Vaccination_Rate_Per_100
FROM 
    covid19_db..CovidVaccinations
GROUP BY 
    location
ORDER BY 
    Vaccination_Rate_Per_100 DESC;


--Monthly Vaccination Trends for a Specific Country
SELECT 
    location AS Country,
    YEAR(date) AS Year,
    MONTH(date) AS Month,
    SUM(new_vaccinations) AS Total_New_Vaccinations
FROM 
    covid19_db..CovidVaccinations
--WHERE 
--    location = 'United States'
GROUP BY 
    location, YEAR(date), MONTH(date)
ORDER BY 
    Year, Month;

--Countries with the Lowest Vaccination Rate in Relation to Population Density
SELECT 
    location AS Country,
    MAX(total_vaccinations_per_hundred) AS Vaccination_Rate_Per_100,
    AVG(population_density) AS Avg_Population_Density
FROM 
    covid19_db..CovidVaccinations
GROUP BY 
    location
ORDER BY 
    Vaccination_Rate_Per_100 ASC


--Correlation Between GDP per Capita and Vaccination Rates
SELECT 
    location AS Country,
    AVG(gdp_per_capita) AS Avg_GDP_Per_Capita,
    MAX(total_vaccinations_per_hundred) AS Vaccination_Rate_Per_100
FROM 
    covid19_db..CovidVaccinations
GROUP BY 
    location
ORDER BY 
    Avg_GDP_Per_Capita DESC;

--Total Boosters Administered by Continent
SELECT 
    continent,
    SUM(total_boosters) AS Total_Boosters_Administered
FROM 
    covid19_db..CovidVaccinations
GROUP BY 
    continent
ORDER BY 
    Total_Boosters_Administered DESC;
