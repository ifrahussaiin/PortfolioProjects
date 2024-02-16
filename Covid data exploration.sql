
Select * from PortfolioProject.dbo.covidDeath where continent is not null
order by 3,4

Select * from PortfolioProject.dbo.covidDeath
order by 3,4 Desc

Select * from PortfolioProject.dbo.covidvaccinations
order by 3,4

---SELECT DATA THAT WE ARE GOING TO BE USING--

Select location,date,population,total_cases,new_cases,total_deaths
from PortfolioProject.dbo.covidDeath 
ORDER BY 1,2

---Looking at total cases vs total death--
SELECT 
    date, 
    location, 
    total_cases,
    total_deaths, 
    CASE 
        WHEN TRY_CONVERT(float, total_cases) > 0 THEN (TRY_CONVERT(float, total_deaths) / TRY_CONVERT(float, total_cases)) * 100
         
    END AS DeathPercentage
FROM 
    PortfolioProject.dbo.covidDeath 
WHERE 
    TRY_CONVERT(float, total_cases) > 0 AND (TRY_CONVERT(float, total_deaths) / TRY_CONVERT(float, total_cases)) * 100 > 1
ORDER BY 
    date DESC, 
    location;

---looking as total cases vs population--
--shows what percentage of population got covid--

select date, location, population, total_cases,
case 
when TRY_CONVERT(float, total_cases) > 0 then (TRY_CONVERT(float,total_cases) / TRY_CONVERT(float,population))*100
end as percentPopulationInfected
from PortfolioProject.dbo.covidDeath
where location like '%pakistan%'
order by 1 desc,2


---looking at countries with higher infection rate compared to population--

SELECT  
    location, 
    MAX(population) AS population, 
    MAX(total_cases) AS HighestInfectCount,
    CASE 
        WHEN TRY_CONVERT(float, MAX(total_cases)) > 0 AND MAX(population) > 0 THEN 
            (MAX(total_cases) / MAX(population)) * 100
    END AS percentPopulationInfected
FROM 
    PortfolioProject.dbo.covidDeath
	GROUP BY
    location
	order by percentPopulationInfected desc;


---Showing countries with highest death count per population in float--

SELECT  
    location, 
    MAX(population) AS population, 
    MAX(total_deaths) AS HighestdeathCount,
    CASE 
        WHEN TRY_CONVERT(float, MAX(total_deaths )) > 0 AND MAX(population) > 0 THEN 
            (MAX(total_deaths ) / MAX(population) ) * 100
    END AS TotalDeathCount
FROM 
    PortfolioProject.dbo.covidDeath
	where location like '%states%' and continent is  not null
	GROUP BY
    location
	order by TotalDeathCount desc;

--Showing countries with highest death count per population in int--

SELECT  
    location, 
    MAX(population) AS population, 
    MAX(total_deaths) AS HighestdeathCount,
    CASE 
        WHEN MAX(cast(total_deaths as int)) > 0 AND MAX(cast(population as int)) > 0 THEN 
            (MAX(cast(total_deaths as int)) / NULLIF(MAX(cast(population as int)), 0) * 100)
    END AS TotalDeathCount
FROM 
    PortfolioProject.dbo.covidDeath
WHERE 
    location LIKE '%states%' AND continent IS NOT NULL
GROUP BY
    location
ORDER BY
    TotalDeathCount DESC;

	---showing continent with highest death count per population--

	SELECT  
    continent, 
    MAX(population) AS population, 
    MAX(total_deaths) AS HighestdeathCount,
    CASE 
        WHEN TRY_CONVERT(float, MAX(total_deaths )) > 0 AND MAX(population) > 0 THEN 
            (MAX(total_deaths ) / MAX(population) ) * 100
    END AS TotalDeathCount
FROM 
    PortfolioProject.dbo.covidDeath
	where continent is  not null
	GROUP BY
    continent
	order by TotalDeathCount desc;

	
	---Global Numbers--


SELECT 
    date, 
 
    total_cases,
    total_deaths, 
    CASE 
        WHEN TRY_CONVERT(float, total_cases) > 0 THEN (TRY_CONVERT(float, total_deaths) / TRY_CONVERT(float, total_cases)) * 100
         
    END AS DeathPercentage
FROM 
    PortfolioProject.dbo.covidDeath 
WHERE 
    continent is not null
ORDER BY 
    1 DESC, 2
   
   

SELECT 
    date, 
    SUM(new_cases) AS total_new_cases,
    SUM(new_deaths) AS total_new_deaths, 
    CASE 
        WHEN SUM(new_deaths) > 0 THEN (SUM(new_cases) * 100.0 / SUM(new_deaths))
        ELSE 0 -- or NULL, depending on what you want to display
    END AS DeathPercentage
FROM 
    PortfolioProject.dbo.covidDeath 
WHERE 
    continent IS NOT NULL
GROUP BY 
    date
ORDER BY 
    1,2;

	--Using CTE--
	---looking at total population vs vaccinations---

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations, 
        Sum(cast(vac.new_vaccinations as bigint)) Over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
    FROM 
        PortfolioProject.dbo.covidDeath dea
    JOIN 
        PortfolioProject.dbo.covidvaccinations vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    where 
        dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100 from PopvsVac


---Temp Table---

Drop Table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(continent nvarchar (255), 
       location nvarchar (255), 
       date datetime, 
        population numeric, 
       new_vaccinations numeric,
	   RollingPeopleVaccinated numeric)

insert into #PercentPopulationVaccinated

    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations, 
        Sum(cast(vac.new_vaccinations as bigint)) Over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
    FROM 
        PortfolioProject.dbo.covidDeath dea
    JOIN 
        PortfolioProject.dbo.covidvaccinations vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    --where 
    --    dea.continent is not null

		select *, (RollingPeopleVaccinated/population)*100 from #PercentPopulationVaccinated 


		---Creating Views to store data for later visualization--

		Create view PercentPopulationVaccinated as 
		 SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations, 
        Sum(cast(vac.new_vaccinations as bigint)) Over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
    FROM 
        PortfolioProject.dbo.covidDeath dea
    JOIN 
        PortfolioProject.dbo.covidvaccinations vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    --where 
    --    dea.continent is not null

	select * from PercentPopulationVaccinated

	






 










