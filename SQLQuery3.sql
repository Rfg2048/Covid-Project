Select *
From CovidDeaths
Order by 3,4

--Select *
--From CovidVaccinations
--Order by 3,4

-- Select Data to be used

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Order by 1,2

-- Total Cases vs Total Deaths using Procedure

Create procedure DeathByCountry

@Location nvarchar(100)

as
Select Location, date, total_cases, total_deaths, Round((total_deaths/total_cases) * 100, 2) as DeathPercentage
From CovidDeaths
Where location like @Location
Order by 1,2

exec DeathByCountry @Location = 'Brazil'
exec DeathByCountry @Location = 'Ireland'

-- Total Cases vs Population

Select Location, date, total_cases, Population, Round((total_deaths/population) * 100, 3) as PopPercentage
From CovidDeaths
Where location like 'Ireland'
Order by 1,2

--Contries with highest infection rate compared to population

Select Location, population, max(total_cases) as HighestRateCount,  Max((total_cases/population) * 100) as TotPercentage
From CovidDeaths
group by Location, Population
Order by TotPercentage desc

--Contries with highest death count per popluation

Select Location, max(cast(total_deaths as int)) as TotDeathCount
From CovidDeaths
where continent is not null
group by Location
Order by TotDeathCount desc

--Continents with highest death count per popluation

Select continent, max(cast(total_deaths as int)) as TotDeathCount
From CovidDeaths
where continent is not null
group by continent
Order by TotDeathCount desc

-- Global numbers

Select date, sum(new_cases) as NewCases, sum(cast(new_deaths as int)) as NewDeaths, round(sum(cast(new_deaths as int))/sum(new_cases) * 100, 2) as DeathPercent
From CovidDeaths
where continent is not null
group by date
Order by 1,2


-- Total popluation vs vaccination using partition by and rolling count

with PopvsVac (continent, location, date, population, new_vaccinations, RollingCounter)
as
(
Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
sum(cast(Vac.new_vaccinations as int)) over (partition by Dth.location order by Dth.location, Dth.date) as RollingCounter
From CovidDeaths Dth
join CovidVaccinations Vac
	on Dth.location = Vac.location
	and Dth.date = Vac.date
where Dth.continent is not null
)

Select *, (RollingCounter/population) * 100 as TotalPercent
from PopvsVac

--Using temp table

Drop Table if exists #PercentPopVaccinated
Create table #PercentPopVaccinated
(
continent nvarchar(100),
Location nvarchar(100),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingCounter numeric
)


Insert into #PercentPopVaccinated
Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
sum(cast(Vac.new_vaccinations as int)) over (partition by Dth.location order by Dth.location, Dth.date) as RollingCounter
From CovidDeaths Dth
join CovidVaccinations Vac
	on Dth.location = Vac.location
	and Dth.date = Vac.date
where Dth.continent is not null

Select *, (RollingCounter/population) * 100 as TotalPercent
from #PercentPopVaccinated


-- Creating view to store data

create view PercentPopulationVaccinated as

Select Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations,
sum(cast(Vac.new_vaccinations as int)) over (partition by Dth.location order by Dth.location, Dth.date) as RollingCounter
From CovidDeaths Dth
join CovidVaccinations Vac
	on Dth.location = Vac.location
	and Dth.date = Vac.date
where Dth.continent is not null
--order by 2,3