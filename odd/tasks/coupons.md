# Feature: Coupons Service with Expiration and Single-Use Constraints
Status: in_progress
Created: 2026-11-08

## Specs
- S1: Valid coupon application calculates correct discount based on percentage.
- S2: Expired coupon raises CouponExpiredError.
- S3: Already used coupon for the same customer raises CouponAlreadyUsedError.

## Tasks
- [x] T1: Implement CouponService, domain exceptions, and unit tests (Specs: S1, S2, S3 | Route: direct inline | Status: verified 7/7 tests passed)

## Log
- L1: User requested end-to-end verification of Gentle AI stack with a coupon service with expiration, single-use per customer, strict TDD, and adversarial review.
