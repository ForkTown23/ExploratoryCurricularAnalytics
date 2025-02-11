from typing import Dict
from api import Session

from parse import major_codes, major_plans
from ucsd import university


def get_plan_id(
    session: Session, curriculum_ids: Dict[str, int], major_code: str, college_code: str
) -> int:
    return session.get_degree_plans(curriculum_ids[major_code])[
        f"{major_code}/{university.college_names[college_code]}"
    ]


if __name__ == "__main__":
    import sys
    from output import MajorOutput
    from upload import MajorUploader, track_uploaded_curricula

    session = MajorUploader()

    mode = sys.argv[1]
    major_code = sys.argv[2]
    college_code = sys.argv[3] if len(sys.argv) >= 4 else None
    year = 2021

    with track_uploaded_curricula(year) as curricula:
        if mode == "edit":
            if college_code:
                output = MajorOutput.from_json(
                    major_plans(year)[major_code],
                    session.get_curriculum(curricula[major_code]),
                )
                plan_id = get_plan_id(session, curricula, major_code, college_code)
                session.edit_degree_plan(plan_id, output.output_json(college_code))
                print(f"https://curricularanalytics.org/degree_plans/{plan_id}")
            else:
                session.edit_major(
                    curricula[major_code],
                    major_codes()[major_code],
                    year,
                    start_id=600,
                    log=True,
                )
        elif mode == "delete":
            if college_code:
                plan_id = get_plan_id(session, curricula, major_code, college_code)
                session.destroy_degree_plan(plan_id)
            else:
                session.destroy_curriculum(curricula[major_code])
                del curricula[major_code]
        else:
            raise ValueError(f"Unknown mode '{mode}'")
