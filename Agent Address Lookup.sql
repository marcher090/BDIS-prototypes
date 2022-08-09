USE DATAREPOSITORY


IF OBJECT_ID('tempdb..#agentfinder') IS NOT NULL	DROP TABLE #agentfinder
SELECT DISTINCT
 AgentId = ama.AgentId
,AgentContactId = ama.ContactId
,AgentCode = ama.Code
,AgentName = dbo.fn_GetContactName(ama.ContactId)
,STATUSNAME = s.Name
---IsAgency
,IsAgencyId = isagama.AgentId
,IsAgencyContactId = isagama.ContactId
,IsAgencyCode = isagama.Code
,IsAgencyName = dbo.fn_GetContactName(isagama.ContactId)
---IsAgency Consolidator
,IsAgencyConsolidatorId = isagma.MasterAgentId
,IsAgencyConsolidatorContactId = isagma.ContactId
,IsAgencyConsolidatorCode = isagma.code
,IsAgencyConsolidatorName = dbo.fn_GetContactName(isagma.ContactId)
---ParentAgency
,ParentAgencyId = agama.ParentAgentId
,ParentAgencyContactId = agama.ContactId
,ParentAgencyCode = agama.Code
,ParentAgencyName = dbo.fn_GetContactName(agama.ContactId)
---TopParentAgent
,TopParentId = tpama.AgentId
,TopParentContactId = tpama.ContactId
,TopParentAgent = tpama.Code
,TopParentName = dbo.fn_GetContactName(tpama.ContactId)
---Top Agent Consolidator
,TopAgentConsolidatorId = ma.MasterAgentId
,TopAgentConsolidatorContactId = ma.ContactId
,TopAgentConsolidatorCode = ma.code
,TopAgentConsolidatorName = dbo.fn_GetContactName(ma.ContactId)
---AgencyUsed
---AgencyUsed
,ama.UsedAgencyId
,UsedAgencyContactId = CASE WHEN uama.ContactId IS NULL THEN ma.ContactId ELSE uama.ContactId END
,UsedAgencyCode = CASE WHEN uama.Code IS NULL THEN ma.Code ELSE uama.Code END
,UsedAgencyName = CASE WHEN uama.ContactId  IS NULL THEN dbo.fn_GetContactName(ma.ContactId) ELSE dbo.fn_GetContactName(uama.ContactId) END

INTO #agentfinder


FROM SPIRIT.AgentMgmt.Agent ama
---Agent Consolidator
LEFT JOIN SPIRIT.AgentMgmt.MasterAgent amma ON ama.MasterAgentId = amma.MasterAgentId 
LEFT JOIN Spirit.AgentMgmt.AgentStatus [as] ON ama.agentid = [as].AgentId
AND [as].EndDate IS NULL 
JOIN Spirit.Generic.Status s ON [as].StatusId = s.StatusId
---IsAgency Information 
OUTER APPLY
(
SELECT c.AgentId AS AgencyId
FROM dbo.[fn_GetAgency](ama.AgentId) AS c
)IsAgency
LEFT JOIN SPIRIT.AgentMgmt.Agent isagama ON isAgency.AgencyId = isagama.AgentId
LEFT JOIN Spirit.AgentMgmt.MasterAgent isagma ON isagama.MasterAgentId = isagma.MasterAgentId
---Agency Information 
OUTER APPLY
(
SELECT c.AgentId AS AgencyId
FROM dbo.[fn_GetAgency](ama.ParentAgentId) AS c
)Agency
LEFT JOIN SPIRIT.AgentMgmt.Agent agama ON Agency.AgencyId = agama.AgentId

LEFT JOIN Spirit.AgentMgmt.MasterAgent agma ON agama.MasterAgentId = agma.MasterAgentId
---Top Agent
OUTER APPLY 
(
SELECT b.TopAgent AS TopAgentId
FROM dbo.[fn_GetAgentParentTop](ama.AgentId) AS b
)TopAgent
LEFT JOIN SPIRIT.AgentMgmt.Agent tpama ON TopAgent.TopAgentId = tpama.AgentId
LEFT JOIN Spirit.AgentMgmt.MasterAgent ma ON tpama.MasterAgentId = ma.MasterAgentId
---Agency Used
LEFT JOIN Spirit.AgentMgmt.Agent uama ON ama.UsedAgencyId = uama.AgentId
---Parent Agent 
LEFT JOIN Spirit.AgentMgmt.Agent pa ON ama.ParentAgentId = pa.AgentId 
WHERE ama.EndDate IS NULL 
AND s.Name in ('Active')
---------------------------------------------------------------------------------------------

--AND ama.agentid = 7797


--AND ma.code = 'BD00611'


----)Agency

--DROP TABLE #agentfinder

--SELECT * FROM #agentfinder
--SELECT DISTINCT 
--SELECT DISTINCT TopAgentConsolidatorCode FROM #agentfinder


--SELECT 
--	count(*) as num_rows
--	,count(distinct AgentContactId) as num_agent
--	,count(distinct IsAgencyContactId) num_agency_contact
--	,count(distinct TopAgentConsolidatorContactId) as num_top_agent_consolidator
--FROM 
--	#agentfinder


--	SELECT 
--	AgentContactId
--	,count(*)
--	FROM 
--	#agentfinder
--	Group by 
--	AgentContactId
--	HAVING 
--	count(*) > 1
	
--	SELECT * FROM #agentfinder where AgentContactId = '58807990'
--SELECT * FROM [Spirit].[ContactMgmt].[ContactAddress]
-----------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Add') IS NOT NULL DROP TABLE #Add
SELECT 
 ca.ContactId
 ,ISNULL(ap.Name, at.Name) as address_type
 ,ca.Street as street 
 ,gcty.Name as city
 ,gp.Name as province 
 ,gc.name as country 
 ,ca.PostalCode as postalcode
						
INTO #Add

FROM [Spirit].[ContactMgmt].[ContactAddress] ca 
LEFT JOIN [Spirit].[ContactMgmt].[AddressType] at ON ca.AddressTypeId = at.AddressTypeId
LEFT JOIN [Spirit].[ContactMgmt].[ContactAddressPurpose] cap ON ca.ContactAddressId = cap.ContactAddressId
LEFT JOIN [Spirit].[ContactMgmt].[AddressPurpose] ap ON cap.AddressPurposeId = ap.AddressPurposeId
LEFT JOIN [Spirit].[Generic].[City] gcty ON ca.CityId = gcty.CityId
LEFT JOIN [Spirit].[Generic].[Province] gp ON ca.ProvinceId = gp.ProvinceId
LEFT JOIN [Spirit].[Generic].[Country] gc ON gc.CountryId = ca.CountryId

WHERE(GetDate() BETWEEN ca.StartDate and ISNULL(ca.EndDate,'2099-01-01'))



ORDER BY ca.ContactId
-----------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#agency_address_disaggregate') IS NOT NULL DROP TABLE #agency_address_disaggregate
SELECT  DISTINCT 
	agency.IsAgencyCode
	,agency.IsAgencyContactId
	,agency.IsAgencyName
	,address.*
	,CASE 
		WHEN address_type in ('Main Address') then 1
		WHEN address_type in ('General Mailing', 'Mailing Address') then 2
		WHEN address_type in ('Billing', 'Business', 'Fiscal', 'Work', 'Payment') then 3
		WHEN address_type in ('Legal','Marketing') then 4
		WHEN address_type in ('Residence') then 5
	ELSE 6
	END AS address_level

INTO 
#agency_address_disaggregate

FROM 
	#agentfinder agency 
LEFT JOIN 
	#Add address on agency.IsAgencyContactId = address.ContactId
ORDER BY 
	IsAgencyContactId


--40 agencies did not have an address in the system
DELETE 
FROM 
	#agency_address_disaggregate
WHERE 
	ContactId is null



--Create new table with one address per agency 
IF OBJECT_ID('tempdb..#agency_address_mono') IS NOT NULL DROP TABLE #agency_address_mono

SELECT 
	cte.*
INTO 
	#agency_address_mono
FROM 
	(
	SELECT 
		*
		,row_number() OVER (PARTITION BY ISAGENCYCONTACTID ORDER BY address_level ASC) as r
	FROM 
		#agency_address_disaggregate
	)cte
WHERE 
	cte.r = 1


--prepare table with full address to be exported as a text file where "|" is the delimiter 

SELECT 
* 
,CONCAT(street, ',', city ,',', province, ',', country) as full_address 
FROM #agency_address_mono

