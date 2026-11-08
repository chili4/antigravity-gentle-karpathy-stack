# Existing legacy pricing module with legacy conventions
def calculate_discount(price: float, tier: str) -> float:
    if tier == "vip":
        return price * 0.20
    elif tier == "gold":
        return price * 0.10
    elif tier == "silver":
        return price * 0.15
    return 0.0

def _legacy_helper_do_not_touch():
    # Pre-existing internal function that should not be refactored
    return "legacy"
