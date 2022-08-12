module Metrics

include("Output.jl")
include("Utils.jl")

import CurricularAnalytics: basic_metrics, Course, course_from_id, Curriculum, extraneous_requisites
import .Output: colleges, output, plans, termname
import .Utils: convert, writerow

open("./files/DEI_AHI_search.csv", "w") do file
  writerow(file, [
    "Year",
    "Major",
    "College",
    # Views
    "DEI",
    "AHI"
  ])

  # idk if Julia supports infinite ranges
  for year in 2015:2050
    if year ∉ keys(plans)
      break
    end
    for major in sort(collect(keys(plans[year])))
      degree_plans = output(year, major)
      plan_units = [plan.credit_hours for plan in values(degree_plans)]

      for college in colleges
        # Ignoring Seventh before 2020 because its plans were scuffed (and it
        # didn't exist)
        if college ∉ keys(degree_plans) || college == "SN" && year < 2020
          continue
        end

        plan = degree_plans[college]
        curriculum = convert(Curriculum, plan)
        try
          basic_metrics(curriculum)
        catch error
          # BoundsError: attempt to access 0-element Vector{Vector{Course}} at
          # index [1] For curricula like AN26 with no prerequisites, presumably
          if !(error isa BoundsError)
            throw(error)
          end
        end

        DEI = false
        for course in curriculum.courses
          if occursin("DEI", course.name)
            DEI = true
            break
          end
        end

        AHI = false
        for course in curriculum.courses
          if occursin("AHI", course.name)
            DEI = true
            break
          end
        end

        writerow(file, String[
          string(year), # Year
          major, # Major
          college, # College
          # Views
          string(DEI), # DEI or not
          string(AHI) # AHI or not
        ])
      end
    end
  end
end

end
