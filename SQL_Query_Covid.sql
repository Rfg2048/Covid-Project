--Looking at the tables CovidDeaths and CovidVaccinations

Select *
From CovidDeaths
Order by 3,4

Select *
From CovidVaccinations
Order by 3,4

-- Selecting Data to be used

Select location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Order by 1,2
-- Order by Location (Column 1) and date (Column 2)

-- Total Cases vs Total Deaths using a Procedure

Create Procedure DeathByCountry

@Location nvarchar(100)
as

Select location, date, total_cases, total_deaths, Round((total_deaths/total_cases) * 100, 2) as DeathPercentage
From CovidDeaths
Where location like @Location
Order by 1,2

exec DeathByCountry @Location = 'Brazil'
exec DeathByCountry @Location = 'Ireland'

-- Total Cases vs Population in Ireland

Select location, date, total_cases, population, Round((total_deaths/population) * 100, 3) as PopPercentage
From CovidDeaths
Where location like 'Ireland'
Order by 1,2

--Countries with highest infection rate compared to population

Select location, population, max(total_cases) as HighestRateCount,  Max((total_cases/population) * 100) as TotPercentage
From CovidDeaths
Where continent is not null
Group by location, population
Order by TotPercentage desc

--Countries with highest death count per popluation

Select location, max(cast(total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc

--Continents with highest death count per popluation

Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc

-- Global numbers of new cases vs new deaths

Select date, sum(new_cases) as NewCases, sum(cast(new_deaths as int)) as NewDeaths, round(sum(cast(new_deaths as int))/sum(new_cases) * 100, 2) as DeathPercentage
From CovidDeaths
Where continent is not null
Group by date
Order by 1,2

-- Total population vs vaccination using CTE, Join, Alias and partition by

With PopvsVac (continent, location, date, population, new_vaccinations, RollingCounter)
as

(
Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
sum(cast(Vac.new_vaccinations as int)) over (partition by Dth.location order by Dth.location, Dth.date) as RollingCounter

From CovidDeaths Dth
join CovidVaccinations Vac
	on Dth.location = Vac.location
	and Dth.date = Vac.date
Where Dth.continent is not null
)

Select *, (RollingCounter/population) * 100 as TotalPercent
From PopvsVac

--Using temp table

Drop table if exists #PercentPopVaccinated

Create table #PercentPopVaccinated
(
continent nvarchar(100),
location nvarchar(100),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCounter numeric
)


Insert into #PercentPopVaccinated
Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
sum(cast(Vac.new_vaccinations as int)) over (partition by Dth.location order by Dth.location, Dth.date) as RollingCounter

From CovidDeaths Dth
join CovidVaccinations Vac
	on Dth.location = Vac.location
	and Dth.date = Vac.date
Where Dth.continent is not null

Select *, (RollingCounter/population) * 100 as TotalPercent
From #PercentPopVaccinated
order by 2,3

-- Creating view to store data

Create view PercentPopulationVaccinated
as

Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
sum(cast(Vac.new_vaccinations as int)) over (partition by Dth.location order by Dth.location, Dth.date) as RollingCounter
From CovidDeaths Dth
join CovidVaccinations Vac
	on Dth.location = Vac.location
	and Dth.date = Vac.date
Where Dth.continent is not null