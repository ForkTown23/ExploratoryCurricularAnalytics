module Metrics

include("Output.jl")
include("Utils.jl")

import CurricularAnalytics: basic_metrics, Course, course_from_id, Curriculum, extraneous_requisites
import .Output: colleges, output, plans, termname
import .Utils: convert, writerow

open("./files/metrics_fa12_term_by_term.csv", "w") do file
  writerow(file, [
    "Year",
    "Major",
    "College",
    # Views
    "Term #",
    "# of Courses",
    "Complexity score",
    "Units #",
    "Centrality score",
    "Blocking factor",
    "Delay factor"
  ])

  # idk if Julia supports infinite ranges
  for year in 2015:2050
    if year ∉ keys(plans)
      break
    end
    println(year)
    for major in sort(collect(keys(plans[year])))
      degree_plans = output(year, major)
      plan_units = [plan.credit_hours for plan in values(degree_plans)]

      for college in colleges
        # Ignoring Seventh before 2020 because its plans were scuffed (and it
        # didn't exist)
        println(college)
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

        term_numb = 1
        for term in plan.terms
          term_courses = length(term.courses)

          term_compl = sum(
            course.metrics["complexity"]
            for course in term.courses;
            init=0
          )

          term_centr = sum(
            course.metrics["centrality"]
            for course in term.courses;
            init=0
          )

          term_blocking = sum(
            course.metrics["blocking factor"]
            for course in term.courses;
            init=0
          )

          term_delay = sum(
            course.metrics["delay factor"]
            for course in term.courses;
            init=0
          )

          term_units = sum(
            course.credit_hours
            for course in term.courses;
            init=0
          )

          writerow(file, String[
            string(year), # Year
            major, # Major
            college, # College
            # Views
            string(term_numb), # Term
            string(term_courses), # # of courses
            string(term_compl), # Complexity score
            string(term_units), # Units
            string(term_centr), # Centrality score
            string(term_blocking), # Blocking factor
            string(term_delay) # Delay factor            
          ])
          term_numb += 1
        end
      end
    end
  end
end

end
