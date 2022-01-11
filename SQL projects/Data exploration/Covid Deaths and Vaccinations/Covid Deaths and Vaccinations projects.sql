--This attempt to explore data for futher visualization 
--Data source: 
			https://ourworldindata.org/covid-vaccinations
			https://ourworldindata.org/covid-deaths
--Reference: @Alex the Analyst

USE [Porfolio project]
GO
-- overview of table

SELECT * from dbo.CovidDeath
order by 3,4

select * from dbo.CovidVacination
order by 3,4

--1. looking at total case versus population in Vietnam
--Show the percentage of population got covid

create view Vietnam_DeathRate as
(
select location, date, total_cases, new_cases, total_deaths, population, round(total_cases/population*100,2) as 'percentage on population' from dbo.CovidDeath
where location like 'Vietnam'
--order by 2
)

--2. Looking at the country with highest infection rate compared to population recently

create view infection_rate_byCountry as
(
select location, population, max(total_cases) as infection_cases_sofar, round(max((total_cases/population))*100,4) as 'percentage_on_infection' from dbo.CovidDeath
group by location, population
--order  by  4 desc
)
select * from infection_rate_byCountry
order by percentage_on_infection desc

--3. Loking at total death by location

create view total_death_byCountry as
(
select location, max(cast(total_deaths as int)) as total_death_so_far
from dbo.CovidDeath
where continent is not null
group by location
)
select * from total_death_byCountry
order by 1

--4. Loking at total death by continent
create view total_death_byCont as
(
select continent, sum(cast(new_deaths as int)) as total_death_so_far
from dbo.CovidDeath
where continent IS NOT NULL
group by continent
)
select * from total_death_byCont
order by 1

--5. Breakdown global death rate by date

select date, sum(cast(new_cases as int)) as new_cases, sum(cast(new_deaths as int))as new_deaths, sum(cast(new_deaths as float))/sum(new_cases) * 100 as deathrate --float*int=float
from dbo.CovidDeath
where continent is not null
group by date
order  by date,2 desc
--5.5 Global infection by date
create view GlobalInfectionByDate as
(
select location,population, date, max(total_cases) as total_cases_so_far, max(total_cases/population) * 100 as Percent_Infection --float*int=float
from dbo.CovidDeath
where continent is not null
group by location, date, population

)
select * from GlobalInfectionByDate
order by Percent_Infection desc

--6. Total death rate of the world 

select sum(cast(new_cases as int)) as total_cases, sum(cast(new_deaths as int))as new_deaths, sum(cast(new_deaths as float))/sum(new_cases) * 100 as Deathrate --float*int=float
from dbo.CovidDeath
where continent is not null

--7. Looking at total polation has fully vacination 

select dea.location, dea.population  as population, max(cast(vac.people_fully_vaccinated as float)) as fully_vacinated_people,max(cast(vac.people_fully_vaccinated as float))/dea.population*100 as total_vacine_rate 
FROM dbo.CovidDeath dea
join dbo.CovidVacination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where vac.continent is not null 
group by dea.location,dea.population
order by 4 desc

	--7.5 --/case of Gilbraltar/ what wrong with this data ??

select dea.date,vac.people_fully_vaccinated, dea.population, 
cast(vac.people_fully_vaccinated as float)/dea.population*100 as total_vacine_rate 
from dbo.CovidDeath dea
join dbo.CovidVacination vac
on dea.location = vac.location
	and dea.date = vac.date
	where dea.location like 'Gibraltar' 
	order by date desc

--8. Looking at new vacination

select date, location, new_vaccinations from dbo.CovidVacination
where new_vaccinations is not null
and continent is not null
order by location 

--9. Looking at rolling number of new_vaccinations by locations and calculate vaccination rate

	-- USE CTE
With PopvsVAc (Location, Population, Date, New_vaccinations, Rolling_vaccinations)
as(
select dea.location, dea.population,dea.date, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingNumberNewVaccine 
from dbo.CovidDeath dea
join dbo.CovidVacination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where vac.continent is not null 
	and new_vaccinations is not null
--order by 1,4 asc
)

select *, Rolling_vaccinations/Population*100 as Vaccinations_Rate 
from PopvsVAc
order by Location

	--USE TEMP Table

drop table if exists #RollingVaccinationOverPopular
create table #RollingVaccinationOverPopular
(
Location nvarchar(225), 
Population numeric, 
Date datetime, 
New_vaccinations numeric, 
Rolling_vaccinations numeric,
)
insert into #RollingVaccinationOverPopular
	select dea.location, dea.population,dea.date, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingNumberNewVaccine 
	from dbo.CovidDeath dea
	join dbo.CovidVacination vac
		on dea.location = vac.location
		and dea.date = vac.date
		where vac.continent is not null 
		and new_vaccinations is not null
select *, Rolling_vaccinations/Population*100 as VaccinationsRate from #RollingVaccinationOverPopular
order by Location

	--Create view for storing data as later visulaization materials 

create view VaccinatedPopulationRate as
(
select dea.location, dea.population,dea.date, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as RollingNumberNewVaccine 
	from dbo.CovidDeath dea
	join dbo.CovidVacination vac
		on dea.location = vac.location
		and dea.date = vac.date
		where vac.continent is not null 
		and new_vaccinations is not null
		)
select * from VaccinatedPopulationRate