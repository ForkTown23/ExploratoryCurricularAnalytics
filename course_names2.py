import re
from parse import major_plans


def simplify(title: str) -> str:
    # This doesn't have to be perfect. Better to keep than remove
    # Keep DF/IEn
    title = title.strip("^* ¹")
    if match := re.match(r"(GE|DEI) */ *(GE|AWP|DEI)", title):
        return "DEI" if match.group(1) == "DEI" or match.group(2) == "DEI" else "GE"
    title = re.sub(r" */ *(GE|AWP|DEI)$", "", title, flags=re.I)
    title = re.sub(
        r" *\(\*?(see note|DEI APPROVED|DEI)\*?\)$|^1 ", "", title, flags=re.I
    )
    title = re.sub(r" +", " ", title)
    return title


course_titles = {
    course.course_title: f"{major_plan.major_code} {college}"
    for major_plan in major_plans.values()
    for college, plan in major_plan.plans.items()
    for quarter in plan.quarters
    for course in quarter
}

for title in sorted(course_titles):
    # Currently excludes practicum
    if any(char in title for char in "*^(/-¹") or title.startswith("1"):
        print(f"[{course_titles[title]}] {title}".ljust(80) + simplify(title))
