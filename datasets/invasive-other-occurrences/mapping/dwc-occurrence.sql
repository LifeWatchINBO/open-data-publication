SELECT 
	/* Category: Record */
	[occurrenceID] = 'INBO:NBN:' + TOC.TAXON_OCCURRENCE_KEY
	, [type] =
		CASE
			WHEN RT.SHORT_NAME IN ('auditory record', 'reference/auditory record' ) THEN 'Sound'
			WHEN RT.SHORT_NAME IN ('field record/photographed', '') THEN 'StillImage'
			WHEN RT.SHORT_NAME IN ('Collection/auditory record', 'Collection', 'Collection/field record', 'Collection/reference') THEN 'PhysicalObject'
			WHEN RT.SHORT_NAME IN ('Reference') THEN 'Text'
			WHEN RT.SHORT_NAME IN ('field record', 'None', 'reported to recorder', 'trapped in Malaise trap' ) THEN 'Event'
			ELSE ''
		END	
	, [language] = 'en'
    , [license] = 'http://creativecommons.org/publicdomain/zero/1.0/'
    , [rightsHolder] = 'INBO'
    , [accessRights] = 'http://www.inbo.be/en/norms-for-data-use'
	, [datasetID] = 'http://doi.org/10.15468/1rcpsq'
	, [institutionCode] = 'INBO'
	, [datasetName] = 'invasive-other-occurrences'
	, [ownerInstitutionCode] = 'INBO'
	, [basisOfRecord] =
		CASE
			WHEN RT.SHORT_NAME IN ('Collection/auditory record', 'Collection', 'Collection/field record', 'Collection/reference') THEN 'PreservedSpecimen'
			ELSE 'HumanObservation'
		END

	/* Category: Occurence */		
	, [recordedBy] =
		CASE
			WHEN inbo.[ufn_RecordersPerSample](SA.[SAMPLE_KEY], ' | ') = 'Unknown' THEN '' 
			ELSE inbo.[ufn_RecordersPerSample](SA.[SAMPLE_KEY], ' | ')
		END
	, [individualCount] = Coalesce(Meas.[individualCount], 0)
	--, [verbatimIndividualCount] = TOCD.DATA

	/* Category: Event */
	, [eventID] = SE.SURVEY_EVENT_KEY
	, [eventDate] = 
		CASE 
			WHEN [inbo].[LCReturnVagueDateGBIF](SA.VAGUE_DATE_START, SA.VAGUE_DATE_END, SA.VAGUE_DATE_TYPE, 1) = 'Unknown' THEN ''
			ELSE [inbo].[LCReturnVagueDateGBIF](SA.VAGUE_DATE_START, SA.VAGUE_DATE_END, SA.VAGUE_DATE_TYPE, 1)
		END
	, [continent] = 'Europe'
	, [countryCode] = 'BE'
	, [decimalLatitude] = CONVERT(Nvarchar(20),CONVERT(decimal(12,5),ROUND(COALESCE(SA.Lat,0),5)))
	, [decimalLongitude] = CONVERT(Nvarchar(20),CONVERT(decimal(12,5),ROUND(COALESCE(SA.Long,0),5)))
	, [geodeticDatum] = 'WGS84'
	, [identifiedBy] = COALESCE(
								CASE
									WHEN LTRIM(RTRIM(COALESCE (RTRIM(LTRIM(I.[FORENAME])), RTRIM(LTRIM(I.[INITIALS])), '') + ' ' + COALESCE (RTRIM(LTRIM(I.[SURNAME])), ''))) = 'Unknown' THEN NULL
									ELSE LTRIM(RTRIM(COALESCE (RTRIM(LTRIM(I.[FORENAME])), RTRIM(LTRIM(I.[INITIALS])) ,'') + ' ' + COALESCE (RTRIM(LTRIM(I.[SURNAME])), ''))) 
								END
								, '')
	, [scientificName] = ns.RECOMMENDED_SCIENTIFIC_NAME	
	, [taxonRank] = LOWER(NS.RECOMMENDED_NAME_RANK_LONG)
	, [scientificNameAuthorship] = NS.RECOMMENDED_NAME_AUTHORITY + ISNULL (' ' + NS.RECOMMENDED_NAME_QUALIFIER , '')
	, [vernacularName] = COALESCE(NormNaam.ITEM_NAME, '')
	--, [nomenclaturalCode] = 'ICZN'		
	
	, [verbatimDatasetName] = S.Item_name
		
	--, S.Item_name as 'Survey'
	--, dbo.LCReturnVagueDateShort(SA.VAGUE_DATE_START,SA.VAGUE_DATE_END,SA.VAGUE_DATE_TYPE) as 'Sample Date'
	--, NS.RECOMMENDED_SCIENTIFIC_NAME as 'recommended nameserver scientific name'
	--, ITN .PREFERRED_NAME as 'project species name'
	--, NS.RECOMMENDED_NAME_RANK as 'rank'
	--, ITN.COMMON_NAME as 'vernacular name'
	--, NS.TAXON_NAME as 'nameserver taxon name'
	, NSR.RECOMMENDED_TAXON_VERSION_KEY
	, S.SURVEY_KEY
	, S.ITEM_NAME
	--, TOCD.DATA as 'Count'
	--, LN.ITEM_NAME as 'Sample Location'
	--, LN.LOCATION_NAME_KEY
	--, L.LONG as 'decimalLongitude'
	--, L.LAT as 'decimalLatitude'
	--,-- L.SPATIAL_REF_SYSTEM as 'spatialRefSystem'
	--, L.SPATIAL_REF as 'spatialref'


FROM [dbo].SURVEY S 
	INNER JOIN [dbo].SURVEY_EVENT SE ON S.SURVEY_KEY = SE.SURVEY_KEY 
	INNER JOIN [dbo].SAMPLE SA ON SA.SURVEY_EVENT_KEY = SE.SURVEY_EVENT_KEY 	
	INNER JOIN [dbo].TAXON_OCCURRENCE TOC ON TOC.SAMPLE_KEY = SA.SAMPLE_KEY 
	LEFT JOIN [dbo].TAXON_DETERMINATION TD ON TD.TAXON_OCCURRENCE_KEY = TOC.TAXON_OCCURRENCE_KEY 
	
	LEFT JOIN [dbo].[INDIVIDUAL] I ON I.[NAME_KEY] = TD.[DETERMINER]
	LEFT JOIN [dbo].[RECORD_TYPE] RT ON RT.[RECORD_TYPE_KEY] = TOC.[RECORD_TYPE_KEY]	
		
	INNER JOIN [dbo].INDEX_TAXON_NAME ITN on ITN.TAXON_LIST_ITEM_KEY = TD.TAXON_LIST_ITEM_KEY 
	INNER JOIN [dbo].TAXON_LIST_ITEM tlitd ON tlitd.TAXON_LIST_ITEM_KEY = TD.TAXON_LIST_ITEM_KEY
	INNER JOIN [dbo].[TAXON_RANK] TR ON TR.TAXON_RANK_KEY = tlitd.TAXON_RANK_KEY	
	INNER JOIN [inbo].NAMESERVER_12 NS ON NS.INBO_TAXON_VERSION_KEY = tlitd.TAXON_VERSION_KEY
	INNER JOIN [dbo].NAMESERVER NSR ON NSR.INPUT_TAXON_VERSION_KEY = tlitd.TAXON_VERSION_KEY
	--LEFT JOIN [dbo].TAXON_OCCURRENCE_DATA TOCD ON TOC.TAXON_OCCURRENCE_KEY = TOCD.TAXON_OCCURRENCE_KEY 
	LEFT JOIN [dbo].LOCATION L on SA.LOCATION_KEY = L.LOCATION_KEY 
	LEFT JOIN [dbo].LOCATION_NAME LN on L.LOCATION_KEY = LN.LOCATION_KEY

	LEFT OUTER JOIN ( SELECT tmp.TAXON_OCCURRENCE_KEY
							, [individualCount] =
								SUM(
									CASE
										WHEN ISNUMERIC(tmp.DATA) = 1 
												AND unit = 'Count' 
												AND NOT tmp.DATA = ','
										THEN CONVERT(int, ROUND(tmp.DATA, 0))
										ELSE NULL
									END
									)
					FROM ( 
						SELECT taoMeas.TAXON_OCCURRENCE_KEY
							, MUMeas.SHORT_NAME as unit
							, taoMeas.DATA
							, taoMeas.ACCURACY
							, MQMeas.SHORT_NAME as Qualifier
						FROM dbo.TAXON_OCCURRENCE_DATA  taoMeas
							LEFT JOIN dbo.MEASUREMENT_UNIT MUMeas ON  MUMeas.MEASUREMENT_UNIT_KEY = taoMeas.MEASUREMENT_UNIT_KEY 
							LEFT JOIN dbo.MEASUREMENT_QUALIFIER MQMeas ON  MQMeas.MEASUREMENT_QUALIFIER_KEY = taoMeas.MEASUREMENT_QUALIFIER_KEY
							LEFT JOIN dbo.MEASUREMENT_TYPE MTMeas ON  MTMeas.MEASUREMENT_TYPE_KEY = MQMeas.MEASUREMENT_TYPE_KEY 
					) tmp
					GROUP BY tmp.TAXON_OCCURRENCE_KEY
					) Meas ON Meas.TAXON_OCCURRENCE_KEY = TOC.TAXON_OCCURRENCE_KEY	

	--Normalizing to Vernacular names
	LEFT OUTER JOIN (	SELECT TVen.*
							, ROW_NUMBER() OVER (PARTITION by NS.INPUT_TAXON_VERSION_KEY ORDER BY Tven.ITEM_NAME) as Nbr
							, NS.INPUT_TAXON_VERSION_KEY AS [INBO_TAXON_VERSION_KEY]
						FROM [dbo].[NameServer] NS
							 INNER JOIN dbo.TAXON_LIST_ITEM TLIVen ON TLIVen.PREFERRED_NAME = NS.RECOMMENDED_TAXON_LIST_ITEM_KEY
							 INNER JOIN dbo.TAXON_VERSION TVVen ON TVVen.TAXON_VERSION_KEY = TLIVen.TAXON_VERSION_KEY
							 INNER JOIN dbo.TAXON TVen ON TVVen.TAXON_KEY = TVen.TAXON_KEY
						WHERE TVen.[LANGUAGE] = 'nl'
					) NormNaam on NormNaam.[INBO_TAXON_VERSION_KEY] = tlitd.[TAXON_VERSION_KEY] AND NormNaam.Nbr = 1					
					

WHERE 1=1
	--AND TOC.TAXON_OCCURRENCE_KEY LIKE 'BFN0017900009PDP'  --duplicates!
	AND TD.PREFERRED = 1
	AND LN.PREFERRED = 1
	--AND ISNUMERIC (SUBSTRING(LN.[ITEM_NAME],2,1)) = 0
	--AND TOC.CONFIDENTIAL = 0
	AND NSR.RECOMMENDED_TAXON_VERSION_KEY IN ('NBNSYS0000014604','NHMSYS0001689380','NHMSYS0000544615','INBSYS0000005932','NBNSYS0000142699','NHMSYS0000456744','INBSYS0000012711','INBSYS0000046323','INBSYS0000012718','INBSYS0000032589','NHMSYS0100000968','NHMSYS0000457606','NHMSYS0000457636','INBSYS0000009453','INBSYS0000005533','NBNSYS0000034264','NHMSYS0000457556','NBNSYS0000004710','NBNSYS0100002625','INBSYS0000005534','NHMSYS0000457572','NHMSYS0000457601','NHMSYS0000457575','INBSYS0000011373','NHMSYS0000457576','NBNSYS0000014211','INBSYS0000005539','NBNSYS0000014035','NBNSYS0100002626','NBNSYS0000004711','NHMSYS0000457586','NBNSYS0000014085','NBNSYS0000003425','INBSYS0000005538','NBNSYS0000003426','INBSYS0000005537','NHMSYS0000457607','NHMSYS0000457612','NBNSYS0000013945','NHMSYS0000457616','NBNSYS0000013979','NHMSYS0000457626','NBNSYS0100002628','NBNSYS0000003424','NHMSYS0000457641','NBNSYS0000014875','INBSYS0000005532','NBNSYS0000004713','NBNSYS0000174750','NHMSYS0000458290','INBSYS0000005391','NHMSYS0000458329','INBSYS0000005372','NHMSYS0001593547','NBNSYS0000004420','INBSYS0000005186','NBNSYS0000033914','NBNSYS0000003613','NHMSYS0000459162','NBNSYS0000147973','NHMSYS0000459164','NBNSYS0000003612','INBSYS0000005076','INBSYS0000032618','INBSYS0000032619','INBSYS0000032621','NBNSYS0000002186','NHMSYS0000459784','NHMSYS0000459812','NHMSYS0000459879','NBNSYS0000003187','NBNSYS0000003189','NHMSYS0000460065','NBNSYS0000002117','NHMSYS0000544687','NBNSYS0000005043','NHMSYS0020194859','INBSYS0000004874','NHMSYS0000460478','INBSYS0000004871','NHMSYS0000460487','INBSYS0000004845','NBNSYS0000002350','NHMSYS0000460540','NBNSYS0000033298','INBSYS0000032642','NHMSYS0000080204','NBNSYS0000005147','INBSYS0000012720','NHMSYS0000080217','INBSYS0000004739','NHMSYS0000460832','NBNSYS0000014129','NHMSYS0000460834','NBNSYS0000003611','INBSYS0000012724','NHMSYS0000332758','INBSYS0000012539','NBNSYS0200002718','INBSYS0000009677','INBSYS0000009678','NBNSYS0000003599','INBSYS0000009679','NBNSYS0000004772','INBSYS0000004698','INBSYS0000009682','NHMSYS0100002165','NBNSYS0000004774','NHMSYS0000461148','INBSYS0000004697','NBNSYS0000003600','NBNSYS0200002722','INBSYS0000009691','NBNSYS0200002723','INBSYS0000009684','INBSYS0000009685','INBSYS0000004694','NBNSYS0000003602','NBNSYS0000013948','NBNSYS0200002726','INBSYS0000009686','NBNSYS0000005672','NBNSYS0200003883','INBSYS0000009687','INBSYS0000004692','INBSYS0000004691','INBSYS0000004690','INBSYS0000004689','NHMSYS0000461158','NBNSYS0000040193','INBSYS0000012540','NHMSYS0001593792','INBSYS0000045066','NHMSYS0000530524','NBNSYS0000036962','NHMSYS0000377494','NBNSYS0200002802','NBNSYS0000033673','NHMSYS0000461527','NHMSYS0000461528','NBNSYS0000033485','INBSYS0000004602','NBNSYS0000033674','INBSYS0000004603','NHMSYS0000461525','INBSYS0000012722','INBSYS0000032652','NBNSYS0000002209','NHMSYS0000377495','INBSYS0000045069','INBSYS0000012542','NHMSYS0000544730','INBSYS0000032669','INBSYS0000005251','INBSYS0000033059','NBNSYS0000002106','NBNSYS0000003523','NBNSYS0000005109','NHMSYS0000332764','NBNSYS0000034270','NBNSYS0200003195','NHMSYS0000463858','NBNSYS0000014303','INBSYS0000009805','INBSYS0000003939','NBNSYS0000002679','NHMSYS0000463860','NBNSYS0000003313','NBNSYS0000014176','INBSYS0000003921','INBSYS0000012543','NHMSYS0000534047','NHMSYS0000080227','INBSYS0000012414','INBSYS0000033046','NBNSYS0000002118')
	AND S.SURVEY_KEY IN  ('BFN001790000000B','BFN001790000002P','BFN001790000004P','BFN001790000003G','BFN001790000004K','BFN0017900000044','BFN001790000004J','BFN001790000004C','BFN0017900000019','BFN001790000000A','BFN001790000001U','BFN0017900000006','BFN0017900000023','BFN001790000004F','BFN001790000001W','BFN001790000004I','BFN001790000003O','BFN001790000002O','BFN001790000002H','BFN001790000003C','BFN001790000003V','BFN0017900000040')
