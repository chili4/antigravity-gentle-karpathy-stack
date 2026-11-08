import unittest
from datetime import datetime, timezone, timedelta
from coupon_service import CouponService, Coupon, CouponExpiredError, CouponAlreadyUsedError

class TestCouponService(unittest.TestCase):
    def setUp(self):
        self.service = CouponService()
        self.now = datetime.now(timezone.utc)

    def test_s1_valid_coupon_discount(self):
        # 20% discount on 100.0 with future expiration
        coupon = Coupon(code="SAVE20", discount_percent=20.0, expires_at=self.now + timedelta(days=1))
        self.service.register_coupon(coupon)

        discount = self.service.apply_coupon(code="SAVE20", price=100.0, customer_id="cust_1", current_time=self.now)
        self.assertEqual(discount, 20.0)

    def test_s2_expired_coupon_raises_error(self):
        # Expired yesterday
        coupon = Coupon(code="EXPIRED", discount_percent=10.0, expires_at=self.now - timedelta(days=1))
        self.service.register_coupon(coupon)

        with self.assertRaises(CouponExpiredError):
            self.service.apply_coupon(code="EXPIRED", price=100.0, customer_id="cust_1", current_time=self.now)

    def test_s3_single_use_per_customer_raises_error_on_reuse(self):
        coupon = Coupon(code="ONCE", discount_percent=15.0, expires_at=self.now + timedelta(days=1))
        self.service.register_coupon(coupon)

        # First use succeeds
        self.service.apply_coupon(code="ONCE", price=100.0, customer_id="cust_1", current_time=self.now)

        # Second use by same customer must fail
        with self.assertRaises(CouponAlreadyUsedError):
            self.service.apply_coupon(code="ONCE", price=100.0, customer_id="cust_1", current_time=self.now)

        # Another customer can still use it
        discount = self.service.apply_coupon(code="ONCE", price=100.0, customer_id="cust_2", current_time=self.now)
        self.assertEqual(discount, 15.0)

    def test_concurrent_single_use_prevents_toctou(self):
        import concurrent.futures
        coupon = Coupon(code="RACE", discount_percent=10.0, expires_at=self.now + timedelta(days=1))
        self.service.register_coupon(coupon)

        results = []
        errors = []

        def attempt_redeem():
            try:
                discount = self.service.apply_coupon("RACE", 100.0, "cust_concurrent", self.now)
                results.append(discount)
            except CouponAlreadyUsedError as e:
                errors.append(e)

        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(attempt_redeem) for _ in range(5)]
            concurrent.futures.wait(futures)

        # Exactly ONE thread must succeed; all others must raise CouponAlreadyUsedError
        self.assertEqual(len(results), 1)
        self.assertEqual(len(errors), 4)

    def test_invalid_discount_percent_raises_value_error(self):
        with self.assertRaises(ValueError):
            Coupon(code="BAD", discount_percent=150.0, expires_at=self.now + timedelta(days=1))

    def test_negative_price_raises_value_error(self):
        coupon = Coupon(code="VALID", discount_percent=10.0, expires_at=self.now + timedelta(days=1))
        self.service.register_coupon(coupon)
        with self.assertRaises(ValueError):
            self.service.apply_coupon("VALID", -50.0, "cust_1", self.now)

if __name__ == "__main__":
    unittest.main()
