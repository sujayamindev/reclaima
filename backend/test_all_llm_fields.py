"""
Comprehensive test script for LLM field cleanup.
Tests all vendor fields: store name, phone, email, address, and product name.
"""

import sys
sys.path.insert(0, '.')

from app.services.llm_service import MockLLMService

print("=" * 80)
print("LLM Field Cleanup - Comprehensive Test Suite")
print("=" * 80)

# Initialize mock service
mock_service = MockLLMService()

# Test cases organized by field type
test_cases = {
    "Product Names": [
        ("iPhone 13 256GB blueIMEI : 359433181931874Brand new1 Year Apple Care Warranty", "iPhone 13 256GB blue"),
        ("Samsung Galaxy S21 5G\nIMEI: 123456789\nUnlocked\n2 Year Warranty", "Samsung Galaxy S21 5G"),
        ("MacBook Pro 16-inch M2 Pro Space Gray AppleCare+ Coverage", "MacBook Pro 16-inch M2 Pro Space Gray"),
    ],
    "Store Names": [
        ("BEST . BUY . INC", "Best Buy"),
        ("Apple-Store-Online", "Apple Store"),
        ("mcdonalds restaurant", "Mcdonalds Restaurant"),
        ("7 eleven store", "7 Eleven Store"),
        ("WALMART LLC.", "Walmart"),
    ],
    "Phone Numbers": [
        ("123.456.7890", "+1 (123) 456-7890"),
        ("(123) 456-7890", "+1 (123) 456-7890"),
        ("1 2 3 4 5 6 7 8 9 0", "+1 (123) 456-7890"),
        ("1234567890", "+1 (123) 456-7890"),
    ],
    "Email Addresses": [
        ("info @ shop . com", "info@shop.com"),
        ("INFO@SHOP.COM", "info@shop.com"),
        ("sales@store,com", "sales@store.com"),
        ("support @ best . buy . com", "support@bestbuy.com"),
    ],
    "Addresses": [
        ("123 Main St.Suite 100.Los Angeles.CA.90001", "123 Main St Suite 100, Los Angeles, Ca 90001"),
        ("456 oak street apt 5 new york ny 10001", "456 Oak Street Apt 5 New York Ny 10001"),
        ("789. First. Ave. - San Francisco - CA - 94102", "789 First Ave San Francisco Ca 94102"),
    ],
}

# Run tests
all_passed = True
total_tests = 0
passed_tests = 0

for category, cases in test_cases.items():
    print(f"\n{'=' * 80}")
    print(f"Testing: {category}")
    print('=' * 80)
    
    for input_text, expected_output in cases:
        total_tests += 1
        
        # Call appropriate method based on category
        if category == "Product Names":
            result = mock_service.extract_product_name(input_text)
        elif category == "Store Names":
            result = mock_service.clean_store_name(input_text)
        elif category == "Phone Numbers":
            result = mock_service.clean_phone_number(input_text)
        elif category == "Email Addresses":
            result = mock_service.clean_email(input_text)
        elif category == "Addresses":
            result = mock_service.clean_address(input_text)
        else:
            result = input_text
        
        # Check if result matches expected (case-insensitive for some fields)
        passed = False
        if category in ["Email Addresses", "Store Names", "Addresses"]:
            passed = result.lower() == expected_output.lower()
        else:
            passed = result == expected_output
        
        if passed:
            passed_tests += 1
            status = "✅ PASS"
        else:
            all_passed = False
            status = "❌ FAIL"
        
        print(f"\n{status}")
        print(f"  Input:    {input_text[:70]}..." if len(input_text) > 70 else f"  Input:    {input_text}")
        print(f"  Expected: {expected_output}")
        print(f"  Got:      {result}")
        
        if not passed:
            print(f"  ⚠️  Mismatch detected!")

# Summary
print("\n" + "=" * 80)
print("Test Summary")
print("=" * 80)
print(f"Total Tests:  {total_tests}")
print(f"Passed:       {passed_tests}")
print(f"Failed:       {total_tests - passed_tests}")
print(f"Pass Rate:    {(passed_tests/total_tests)*100:.1f}%")

if all_passed:
    print("\n✅ All tests passed!")
else:
    print("\n⚠️  Some tests failed. Note: Mock implementation uses regex and may not")
    print("   achieve perfect accuracy. Production Bedrock implementation will be better.")

print("\n" + "=" * 80)
print("Next Steps:")
print("=" * 80)
print("1. Commit changes to git")
print("2. Deploy to cloud VM")
print("3. Test with real receipts using Bedrock LLM")
print("4. Monitor logs for accuracy and errors")
print()
