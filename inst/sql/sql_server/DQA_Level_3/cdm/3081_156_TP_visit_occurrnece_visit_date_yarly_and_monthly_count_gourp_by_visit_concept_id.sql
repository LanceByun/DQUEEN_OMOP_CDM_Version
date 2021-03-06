insert into @resultSchema.dq_check_result
select
		 'C156' as check_id
		,38 as startum1
	 	,'visit_date' as stratum2
		,'visit_concept_id' as stratum3
		,visit_concept_id as stratum4
		,year_month as stratum5
		,count_val as count_val
		,null as num_val
		,null as txt_val
  from
  (
    select
      visit_concept_id
     ,year_month
     ,count(*) as count_val
    from
    (select
       visit_concept_id
      ,substring(cast(visit_start_date as varchar),0,8) as year_month
    from @cdmSchema.visit_occurrence)w
    group by visit_concept_id,year_month )v
--
select * into #month_statics from @resultSchema.dq_check_result where check_id = 'C156'
--
insert into @resultSchema.dq_result_statics
select
   s1.check_id
  ,s1.stratum1
  ,s1.stratum2
  ,s1.stratum4 as stratum3
  ,s1.stratum5 as stratum4
  ,'visit date yearly & monthly count group by visit type' as stratum5
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
  (select check_id, stratum1, stratum2,stratum4, stratum5, count_val from #month_statics )as s1
left join
(select distinct
	 stratum4
	,PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY cast(count_val as int)) OVER (PARTITION BY stratum4) p_10
	,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY cast(count_val as int)) OVER (PARTITION BY stratum4) p_25
	,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cast(count_val as int)) OVER (PARTITION BY stratum4) p_75
	,PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY cast(count_val as int)) OVER (PARTITION BY stratum4) p_90
	,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY cast(count_val as int)) OVER (PARTITION BY stratum4) median
  from #month_statics ) as p1
on p1.stratum4 = s1.stratum4
left join
  (select
  		 stratum2
 			,cast(avg(1.0*cast(count_val as int))as float) as avg_val
			,cast(stdev(cast(count_val as int))as float) as stdev_val
			,min(cast(count_val as int)) as min_val
			,max(cast(count_val as int)) as max_val
		 from #month_statics
			group by  stratum2) as s2
on s1.stratum2 = s2.stratum2 ;
