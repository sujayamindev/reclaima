"""
Quick test script for LLM product name extraction.
Tests both mock and real implementations.
"""

import sys
sys.path.insert(0, '.')

from app.services.llm_service import MockLLMService, BedrockLLMService

# Test cases
test_cases = [
    "iPhone 13 256GB blueIMEI : 359433181931874Brand new1 Year Apple Care Warranty",
    "Samsung Galaxy S21 5G\nIMEI: 123456789\nUnlocked\n2 Year Warranty",
    "MacBook Pro 16-inch M2 Pro Space Gray AppleCare+ Coverage",
    "Dell XPS 15\nSerial: ABC123456\nRefurbished",
]

print("=" * 80)
print("Testing MockLLMService (Regex-based)")
print("=" * 80)

mock_service = MockLLMService()

for i, test in enumerate(test_cases, 1):
    result = mock_service.extract_product_name(test)
    print(f"\nTest {i}:")
    print(f"  Input:  {test[:60]}..." if len(test) > 60 else f"  Input:  {test}")
    print(f"  Output: {result}")

print("\n" + "=" * 80)
print("Testing with sample text that should NOT be cleaned (clean product name)")
print("=" * 80)

clean_test = "iPhone 15 Pro Max 512GB"
result = mock_service.extract_product_name(clean_test)
print(f"  Input:  {clean_test}")
print(f"  Output: {result}")
print(f"  Match:  {result == clean_test}")

print("\nDone!")
