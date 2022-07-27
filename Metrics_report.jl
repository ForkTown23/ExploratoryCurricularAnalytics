module Metrics

include("Output.jl")

import CurricularAnalytics: basic_metrics, Course, Curriculum, DegreePlan, isvalid_curriculum, find_term
import .Output: output, plans, termname

function convert(::Type{Curriculum}, plan::DegreePlan)
  c = Curriculum(plan.name, [course for term in plan.terms for course in term.courses])
  if !isvalid_curriculum(c)
    error("$(plan.name) is not a valid curriculum")
  end
  c
end

function writerow(io::IO, row::AbstractVector{String})
  join(io, [
      if any([',', '"', '\r', '\n'] .∈ field)
        "\"$(replace(field, "\"" => "\"\""))\""
      else
        field
      end for field in row
    ], ",")
  write(io, "\n")
  flush(io)
end

open("./files/metrics_fa12_report.csv", "w") do file
  writerow(
    file,
    [
      "Course Name",
      "Year",
      "Major",
      "College",
      # Views
      "Course complexity score",
      "Course centrality score",
      "Term"
    ]
  )

  # idk if Julia supports infinite ranges
  for year in 2015:2050
    if year ∉ keys(plans)
      break
    end
    for major in sort(collect(keys(plans[year])))
      degree_plans = output(year, major)
      plan_units = [plan.credit_hours for plan in values(degree_plans)]

      for college in ["RE", "MU", "TH", "WA", "FI", "SI", "SN"]
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
        for course in curriculum.courses
          writerow(file, String[
            string(course.name), # course name
            string(year), # Year
            major, # Major
            college, # College
            # Views
            string(course.metrics["complexity"]), # course complexity score
            string(course.metrics["centrality"]), # course centrality score
            string(find_term(plan, course))# term
          ])
        end
      end
    end
  end
end

end
