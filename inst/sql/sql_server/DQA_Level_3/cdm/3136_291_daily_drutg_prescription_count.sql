insert into @resultSchema.dq_check_result
select
 'C291' as check_id
,20 as stratum1
,'drug_exposure' as stratum2
,concept_count_val as stratum3
,visit_concept_id as stratum4
,'check the daily drug prescription count' as stratum5
,count_val
,null as num_val
,null as txt_val
from
 (select
 visit_concept_id
,concept_count_val
,count(*) as count_val
from
(select
 v1.visit_concept_id
,d1.person_id
,d1.drug_exposure_start_date
,count(*) as concept_count_val
from
(select
 person_id
,drug_exposure_start_date
,visit_occurrence_id
from @cdmSchema.drug_exposure) as d1
inner join
(select visit_occurrence_id, visit_concept_id from @cdmSchema.visit_occurrence ) as v1
on v1.visit_occurrence_id = d1.visit_occurrence_id
group by  v1.visit_concept_id,d1.person_id,d1.drug_exposure_start_date)w
group by  visit_concept_id,concept_count_val)v
--
select * into #drug_count_statics from @resultSchema.dq_check_result
where check_id = 'C291'
--
insert into @resultSchema.dq_result_statics
select
   s1.check_id
  ,s1.stratum1
  ,s1.stratum2
  ,s1.stratum4 as stratum3
  ,s1.stratum3 as stratum4
	,s1.stratum5
  ,s1.count_val
  ,null as other_val
  ,s2.min_val as min
  ,s2.max_val as max
  ,s2.avg_val as avg
  ,s2.stdev_val as stdev
  ,p1.median
  ,p1.p_10
  ,p1.p_25
  ,p1.p_75
  ,p1.p_90
from
  (select check_id, stratum1, stratum2, stratum3, stratum4,stratum5, count_val from #drug_count_statics)as s1
left join
(select distinct
	 stratum4
	,PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY cast(stratum3 as int)) OVER (PARTITION BY stratum4) p_10
	,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY cast(stratum3 as int)) OVER (PARTITION BY stratum4) p_25
	,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cast(stratum3 as int)) OVER (PARTITION BY stratum4) p_75
	,PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY cast(stratum3 as int)) OVER (PARTITION BY stratum4) p_90
	,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY cast(stratum3 as int)) OVER (PARTITION BY stratum4) median
  from #drug_count_statics) as p1
on p1.stratum4 = s1.stratum4
left join
  (select
  		 stratum4
 			,cast(avg(1.0*cast(stratum3 as int))as float) as avg_val
			,cast(stdev(cast(stratum3 as int))as float) as stdev_val
			,min(cast(stratum3 as int)) as min_val
			,max(cast(stratum3 as int)) as max_val
		 from #drug_count_statics
			group by  stratum4) as s2
on s1.stratum4 = s2.stratum4 ;