/*Written in SQL Server 2016*/

/*Question 1A*/

/*determine the mean, standard deviation, skewness, and kurtosis of hardware prices (per device), grouping by region & device SKU.*/
SELECT  distinct
        t3.[BOM Cost Device],    
        t3.[MB Usage Mo. Device],
        t3.[Other Costs],        
        t3.[18 Digit SKU ID],    
        t3.[15 Digit SKU ID],    
        t3.[8 Digit SKU ID],     
        stat.mean AS Mean,
        stat.stand_dev AS Standard_Deviation,
        /*Skewness and Kurtosis formula sourced from Wikipedia*/
        (Sum(power((t3.[Hardware Price]-stat.mean),3)) / stat.cnt_hardware_prc) / (sum(power((t3.[Hardware Price]-stat.mean),2))) / power(stat.cnt_hardware_prc,1.5) AS Skewness, 
        (Sum(power((t3.[Hardware Price]-stat.mean),4)) / stat.cnt_hardware_prc) / (sum(power((t3.[Hardware Price]-stat.mean),2))) / power(stat.cnt_hardware_prc,2) AS Kurtosis
FROM t3 JOIN 
    /*join t1, t2, t3 in order to aggregate summary statistics*/
    (SELECT  t1.[BOM Cost Device],
             t1.[MB Usage Mo. Device],
             t1.[Other Costs],
             t3.[18 Digit SKU ID],
             t3.[15 Digit SKU ID],
             t3.[8 Digit SKU ID],
             count(t3.[Hardware Price]) AS cnt_hardware_prc,
             /*1st and 2nd moments of distribution*/
             avg(t3.[Hardware Price])   AS mean,
             stdev(t3.[Hardware Price]) AS stand_dev      
     FROM    t1
        join t2 on t2.[Hardware SKU] = t1.[Hardware SKU]
        join t3 on t3.[18 Digit SKU ID] = t2.[18 Digit SKU ID] and t2.[15 Digit SKU ID] = t3.[15 Digit SKU ID] and t2.[8 Digit SKU ID] = t3.[8 Digit SKU ID]
        group by 
             t1.[BOM Cost Device],
             t1.[MB Usage Mo. Device],
             t1.[Other Costs],
             t3.[18 Digit SKU ID],
             t3.[15 Digit SKU ID],
             t3.[8 Digit SKU ID]
             /*Hardware prices need to exist*/
             having count(t3.[Hardware Price]) > 1) AS stat
             /*Join t3 and subquery grouping by region and SKU*/
             on t3.[18 Digit SKU ID] = stat.[18 Digit SKU ID] and t3.[15 Digit SKU ID] = stat.[15 Digit SKU ID] and t3.[8 Digit SKU ID] = stat.[8 Digit SKU ID]
             group by  
                     t1.[BOM Cost Device],
                     t1.[MB Usage Mo. Device],
                     t1.[Other Costs],
                     t3.[18 Digit SKU ID],
                     t3.[15 Digit SKU ID],
                     t3.[8 Digit SKU ID]    
; /*End*/                    
    

/*Question 1B*/

/*determine the mean & standard deviation of hardware annual profit (per device),
grouped by region & device SKU, ignoring outliers (i.e. 5% most profitable & 5% least profitable devices, grouped by
region & device SKU)*/

SELECT 
        [BOM Cost Device],                                  
        [MB Usage Mo. Device],                              
        [Other Costs],                                      
        [18 Digit SKU ID],                                  
        [15 Digit SKU ID],                                  
        [8 Digit SKU ID],
        /*casting columns to larger capacity data type avoids overflow*/
        cast(avg(Hardware_Profit) as BIGINT) AS Mean_Profit,           
        cast(stdev(Hardware_Profit) as BIGINT) AS Sdev_Profit   
        FROM (
        /*calculates the percentile ranking of rows in Hardware_Profit set*/
        /*create new view which excludes outliers based on percentiles*/
        SELECT my_view.*,
               PERCENT_RANK() over(order by my_view.Hardware_Profit) AS rnk
        FROM (
              SELECT 
                     t1.[BOM Cost Device],
                     t1.[MB Usage Mo. Device],
                     t1.[Other Costs],
                     t3.[18 Digit SKU ID],
                     t3.[15 Digit SKU ID],
                     t3.[8 Digit SKU ID],
                     /*Profit = device price less all costs*/
                     (t3.[Hardware Price] - t1.[BOM Cost Device] - t1.[MB Usage Mo. Device] - t1.[Other Costs]) AS Hardware_Profit                 
              FROM t1
                   join t2 on t2.[Hardware SKU] = t1.[Hardware SKU]
                   join t3 on t3.[18 Digit SKU ID] = t2.[18 Digit SKU ID] and t2.[15 Digit SKU ID] = t3.[15 Digit SKU ID] and t2.[8 Digit SKU ID] = t3.[8 Digit SKU ID]) AS my_view) AS ex_outlier
        /*exclude 5% most profitable and 5% least profitable devices from summary statistics*/
        where ex_outlier.rnk between .05 and .95
        group by                                
                [BOM Cost Device],     
                [MB Usage Mo. Device],                 
                [Other Costs],         
                [18 Digit SKU ID],          
                [15 Digit SKU ID],     
                [8 Digit SKU ID]
; /*End*/
