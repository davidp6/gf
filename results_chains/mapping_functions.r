# ----------------------------------------------------
# AUTHOR: Emily Linebarger 
# PURPOSE: Standard functions for mapping results chains
#       
# DATE: Last updated December 2018. 
#-----------------------------------------------------

#
modules_over_time = function(country_name, disease_name, start_year, end_year){
  plot_data = gf_budgets[country == country_name & disease == disease_name & (year >=start_year & year <=end_year),
                        .(country, disease, year, budget, gf_module, gf_intervention, code)] #Use actual numbers. 
  
  check_na_budgets <- plot_data[is.na(budget)] 
  stopifnot(nrow(check_na_budgets)==0)
  
  map_mod_groups <- fread("J:/Project/Evaluation/GF/resource_tracking/multi_country/mapping/category_codebook.csv")
  map_mod_groups = map_mod_groups[, .(category, code)]
  
  plot_data =  merge(plot_data, map_mod_groups, all.x = TRUE, by = c("code"))
  #plot_data[gf_module == "Performance Based Financing", category:="Other"]
  plot_data[gf_module == "Unidentified", category:= "Other"]
  
  #Check that all categories merged correctly. 
  check_na_cats <- plot_data[is.na(category)]
  stopifnot(nrow(check_na_cats) == 0)
  
  #Check that no budgets are NA at this point. 
  check_na_budgets <- plot_data[is.na(budget)]
  stopifnot(nrow(check_na_budgets)==0)
  
  #Aggregate budget by activity/year
  plot_data <- plot_data[, .(budget=sum(budget)), .(year, category)]
  plot_data[is.na(budget), budget:=0] #Don't want to remove these values from graphs entirely, but show that budget was 0 for them. 
  plot_data = plot_data[!duplicated(plot_data)]
  
  #At this point, we want to include all categories of modules, even if they have no spending, as 0. 
  expected_categories <- c('RSSH', 'Treatment', 'Prevention', 'Program management', 'Other')
  for (i in start_year:end_year){
    actual_categories <- plot_data[year == i, category]
    missing_categories <- !expected_categories %in% actual_categories
    for (j in 1:length(missing_categories)){
      if (missing_categories[j] == TRUE){
        print(paste0("Found missing category ", expected_categories[j], " in ", i))
        new_row <- data.table(year = i, category = expected_categories[j], budget = 0)
        plot_data = rbind(plot_data, new_row)
      }
    }
  }
  
  max_db <- (max(plot_data$budget)) #Use the maximum value on the graph to set y-axes dynamically. 
  scale_group = 1 #Group 1 is less than 5 Mil
  if(max_db >= 5000000 & max_db < 25000000){
    scale_group = 2  #Group 2 is between 5mil and 25mil
  }else if(max_db >= 25000000 & max_db < 100000000){
    scale_group = 3 #Group 3 is between 25 mil and 100 mil
  } else if (max_db >=100000000){
    scale_group = 4 #Group 4 is greater than 100 mil
  }
  plot_scale = ifelse(scale_group == 3 | scale_group == 4, 1000000, 1) #If max disbursement is greater than 25 million divide by 1 million. 
  scale_label = ifelse(scale_group == 1 | scale_group == 2, "Budget (USD)", "Budget (Millions USD)")
  plot_ticks = as.numeric(500000)
  if (scale_group == 2){
    plot_ticks = 1000000
  } else if (scale_group == 3){
    plot_ticks = 5
  } else if (scale_group == 4){
    plot_ticks = 50
  }
  
  plot_data = plot_data[, budget:=budget/plot_scale] #Format graph in millions
  max_db <- (max(plot_data$budget)) #Reset maximum after plot has been scaled. 
  y_max <- ifelse(scale_group == 1 | scale_group == 2, round(max_db, 0), round(max_db*10, 0)) #Scale y-axis 
  
  disease_label = "HIV"
  if(disease_name == "tb"){
    disease_label = "TB"
  } else if (disease_name == "malaria"){
    disease_label = "Malaria"
  }
  
  #Factor categories so 'Other' is on the bottom 
  plot_data$category = factor(plot_data$category, c('RSSH', 'Program management', 'Treatment', 'Prevention', 'Other'))
  
  ##Turn on for a stacked bar graph 
  budget_over_time = ggplot(data = plot_data, aes(x = year, y = budget, fill = category)) +
    geom_bar(position = "stack", stat = "identity") +
    theme_bw(base_size = 16) + theme(legend.title = element_blank()) +
    scale_y_continuous(labels = scales::dollar) + 
    scale_x_continuous(labels = seq(from = start_year, to = end_year, by = 2), breaks = seq(from = start_year, to = end_year, by = 2)) +
    scale_fill_brewer(palette = "Accent") +
    labs(x = "Year", y = scale_label, title = paste0("Budget by module in ", country_name, ", for ", disease_label, " ", start_year, "-", end_year))

  #Turn on for a line graph 
  # budget_over_time = ggplot(data = plot_data, aes(x = year, y = budget, group = category, color = category)) +
  #   geom_point() +
  #   geom_line(size = 2, alpha = 0.25) +
  #   theme_bw(base_size = 16) + theme(legend.title = element_blank()) +
  #   scale_y_continuous(breaks = seq(0, y_max, by = plot_ticks), labels = scales::dollar) +
  #   labs(x = "Year", y = scale_label, title = paste0("Budget by module in ", country_name, ", for ", disease_label, " ", start_year, "-", end_year))

  return(budget_over_time)
}

#Accepts a country, a disease, a time period (start and end year, inclusive), and a boolean on whether to include national health expenditure. 
#Return a graph of the funding landscape for the disease in the country over the time period using Financing Global Health actuals. 
funding_landscape = function(country_name, disease_name, start_year, end_year, include_ghe){
  plot_data = fgh_actual[country == country_name & disease == disease_name & (year >=start_year& year <=end_year),
                         .(country, disease, year, financing_source, disbursement)] #Use actual numbers. 
  if (include_ghe == TRUE & country_name == "Guatemala"){ #Need to discuss with David. 
      sicoin_merge <- sicoin[year >= start_year & year <=end_year]
      sicoin_merge <- sicoin_merge[disease == disease_name]
      sicoin_merge <- sicoin_merge[, .(country, disease, year, financing_source, disbursement)]
      sicoin_merge <- sicoin_merge[, financing_source:="Government Health Expenditure"]
      sicoin_merge$disbursement <- as.numeric(sicoin_merge$disbursement)
      plot_data <- rbind(plot_data, sicoin_merge)
  }
  
  #A hacky fix to change financing source to French for DRC reports
  if (1==2){ #Don't run, just leaving here for documentation
    plot_data[financing_source == 'Other bilateral assistance', financing_source:='Autre assistance bilatérale']
    plot_data[financing_source=='NGOs and foundations', financing_source:='ONG et fondations']
    plot_data[financing_source=="UN agencies, The World Bank and other regional development banks", financing_source:='Organismes onusiens, Banque mondiale et autres banques régionales de développement']
    plot_data[financing_source=="U.S. bilateral assistance", financing_source:='Assistance bilatérale américaine']
    plot_data[financing_source=="The Global Fund", financing_source:='Fonds mondial']
  }
  
  plot_data[, disbursement:=sum(disbursement), by = .(financing_source, year)]
  plot_data = plot_data[!duplicated(plot_data)]
  
  #Format variables 
  plot_data$disbursement <- as.numeric(plot_data$disbursement)
  
  #Remove funders with 0 disbursement across time range 
  plot_data[, sum_funder_db:=sum(disbursement), by = c('financing_source')]
  plot_data = plot_data[sum_funder_db != 0]
  plot_data[, sum_funder_db:=NULL]
  
  sum_db <- plot_data[, sum_db:=sum(disbursement), by = c('year')]
  max_db <- (max(sum_db$sum_db)) #Use this to set axes. 
  scale_group = 1 #Group 1 is less than 5 Mil
  if(max_db >= 5000000 & max_db < 25000000){
    scale_group = 2  #Group 2 is between 5mil and 25mil
  }else if(max_db >= 25000000 & max_db < 100000000){
    scale_group = 3 #Group 3 is between 25 mil and 100 mil
  } else if (max_db >=100000000){
    scale_group = 4 #Group 4 is greater than 100 mil
  }
  plot_scale = ifelse(scale_group == 3 | scale_group == 4, 1000000, 1) #If max disbursement is greater than 25 million divide by 1 million. 
  scale_label = ifelse(scale_group == 1 | scale_group == 2, "Disbursement (USD)", "Disbursement (Millions USD)")
  plot_ticks = as.numeric(500000)
  if (scale_group == 2){
    plot_ticks = as.numeric(1000000)
  }else if (scale_group == 3){
    plot_ticks = 5
  } else if (scale_group == 4){
    plot_ticks = 50
  }
  
  plot_data = plot_data[, disbursement:=disbursement/plot_scale] #Scale graph
  sum_db <- plot_data[, sum_db:=sum(disbursement), by = c('year')]
  max_db <- (max(sum_db$sum_db)) #Reset max DB after graph has been scaled.  
  y_max <- ifelse(scale_group == 1 | scale_group == 2, round(max_db, 0), round(max_db*10, 0)) #Scale y-axis 
  
  disease_label = "HIV"
  if(disease_name == "tb"){
    disease_label = "TB"
  } else if (disease_name == "malaria"){
    disease_label = "Malaria"
  }
  
  #Wrap text for expecially long labels
  plot_data[financing_source == "UN agencies, The World Bank and other regional development banks", 
            financing_source:= "UN agencies, The World Bank \nand other regional development banks"]
  
  #Order plot so global fund is on the bottom. 
  plot_data$financing_source <- as.factor(plot_data$financing_source)
  funders <- as.vector(unique(plot_data$financing_source))
  funders = funders[!funders %in% c("The Global Fund")]
  funders = c(funders, "The Global Fund")
  plot_data$financing_source <- factor(plot_data$financing_source, levels = funders)
  plot_data = plot_data[order(financing_source)]
  
  #Generate plot 
  funding_landscape = ggplot(data = plot_data, aes(x = year, y = disbursement, fill = financing_source)) + 
    geom_ribbon(aes(ymin = 0, ymax = disbursement), position = "stack") + 
    theme_bw(base_size = 18) + theme(legend.title = element_blank())+
    scale_y_continuous(expand = c(0,0), breaks = seq(0, y_max, by = plot_ticks), labels = scales::dollar) +
    scale_x_continuous(expand = c(0,0))+
    scale_fill_brewer(palette = "RdYlBu") +
    labs(x = "Year", y = scale_label, title = paste0("Funding landscape in ", country_name, " for ", disease_label, ", ", start_year, "-", end_year))
  
  return(funding_landscape)
  
}

#Source shared FGH function to convert currency
source('J:/Project/IRH/HIV/code/currency_conversion.R')
