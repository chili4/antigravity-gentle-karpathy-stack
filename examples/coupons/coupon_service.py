from dataclasses import dataclass
from datetime import datetime
import threading
from typing import Dict, Set

class CouponExpiredError(Exception):
    """Raised when attempting to apply a coupon past its expiration date."""
    pass

class CouponAlreadyUsedError(Exception):
    """Raised when a customer attempts to reuse a single-use coupon."""
    pass

@dataclass
class Coupon:
    code: str
    discount_percent: float
    expires_at: datetime

    def __post_init__(self):
        if not (0.0 <= self.discount_percent <= 100.0):
            raise ValueError(f"Discount percent must be between 0 and 100, got {self.discount_percent}")

class CouponService:
    def __init__(self):
        self._coupons: Dict[str, Coupon] = {}
        self._usage: Dict[str, Set[str]] = {}
        self._lock = threading.Lock()

    def register_coupon(self, coupon: Coupon) -> None:
        with self._lock:
            self._coupons[coupon.code] = coupon
            if coupon.code not in self._usage:
                self._usage[coupon.code] = set()

    def apply_coupon(self, code: str, price: float, customer_id: str, current_time: datetime) -> float:
        if price < 0.0:
            raise ValueError(f"Price cannot be negative, got {price}")

        with self._lock:
            coupon = self._coupons.get(code)
            if not coupon:
                raise KeyError(f"Coupon '{code}' does not exist.")

            if current_time > coupon.expires_at:
                raise CouponExpiredError(f"Coupon '{code}' expired on {coupon.expires_at}.")

            if customer_id in self._usage[code]:
                raise CouponAlreadyUsedError(f"Customer '{customer_id}' has already used coupon '{code}'.")

            self._usage[code].add(customer_id)
            return price * (coupon.discount_percent / 100.0)
