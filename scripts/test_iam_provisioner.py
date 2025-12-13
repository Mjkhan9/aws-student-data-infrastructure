"""
Unit Tests for IAM Provisioning Script
Author: Mohammad Khan

Tests cover:
- Username validation
- Retry decorator logic
- IAM client creation
- Error handling scenarios
"""

import unittest
import time
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from iam_provisioner import (
    validate_username,
    retry_on_failure,
    USERNAME_PATTERN,
    MAX_RETRIES,
    RETRY_DELAY,
    GROUP_NAME,
    POLICY_ARN
)


class TestUsernameValidation(unittest.TestCase):
    """Test cases for the validate_username function."""

    def test_valid_username_simple(self):
        """Test basic valid username."""
        self.assertTrue(validate_username("valid_user"))

    def test_valid_username_with_numbers(self):
        """Test valid username with numbers."""
        self.assertTrue(validate_username("user123"))

    def test_valid_username_with_allowed_special_chars(self):
        """Test valid username with allowed special characters."""
        self.assertTrue(validate_username("user.name@domain"))
        self.assertTrue(validate_username("user-name"))
        self.assertTrue(validate_username("user_name"))
        self.assertTrue(validate_username("user=name"))
        self.assertTrue(validate_username("user,name"))

    def test_valid_username_single_char(self):
        """Test single character username (minimum length)."""
        self.assertTrue(validate_username("a"))

    def test_valid_username_max_length(self):
        """Test username at maximum length (64 chars)."""
        self.assertTrue(validate_username("a" * 64))

    def test_invalid_username_empty(self):
        """Test that empty string is invalid."""
        self.assertFalse(validate_username(""))

    def test_invalid_username_none(self):
        """Test that None is invalid."""
        self.assertFalse(validate_username(None))

    def test_invalid_username_too_long(self):
        """Test username exceeding 64 characters."""
        self.assertFalse(validate_username("a" * 65))

    def test_invalid_username_with_spaces(self):
        """Test that spaces are not allowed."""
        self.assertFalse(validate_username("user name"))

    def test_invalid_username_special_chars(self):
        """Test that invalid special characters are rejected."""
        self.assertFalse(validate_username("user!name"))
        self.assertFalse(validate_username("user#name"))
        self.assertFalse(validate_username("user$name"))
        self.assertFalse(validate_username("user%name"))
        self.assertFalse(validate_username("user&name"))
        self.assertFalse(validate_username("user*name"))

    def test_invalid_username_non_string(self):
        """Test that non-string types are invalid."""
        self.assertFalse(validate_username(123))
        self.assertFalse(validate_username(['user']))
        self.assertFalse(validate_username({'name': 'user'}))


class TestRetryDecorator(unittest.TestCase):
    """Test cases for the retry_on_failure decorator."""

    def test_successful_function_no_retry(self):
        """Test that successful functions don't retry."""
        call_count = 0

        @retry_on_failure(max_retries=3, delay=0.01)
        def successful_function():
            nonlocal call_count
            call_count += 1
            return "success"

        result = successful_function()
        self.assertEqual(result, "success")
        self.assertEqual(call_count, 1)

    def test_retry_on_transient_failure(self):
        """Test that transient failures trigger retries."""
        call_count = 0

        # Create a mock exception that looks like a throttling error
        mock_exception = Exception("Throttling")
        mock_exception.response = {'Error': {'Code': 'Throttling'}}

        @retry_on_failure(max_retries=3, delay=0.01)
        def failing_then_success():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise mock_exception
            return "success"

        result = failing_then_success()
        self.assertEqual(result, "success")
        self.assertEqual(call_count, 3)

    def test_max_retries_exceeded(self):
        """Test that max retries are respected."""
        call_count = 0

        # Create a mock exception that looks like a throttling error
        mock_exception = Exception("Throttling")
        mock_exception.response = {'Error': {'Code': 'Throttling'}}

        @retry_on_failure(max_retries=3, delay=0.01)
        def always_fails():
            nonlocal call_count
            call_count += 1
            raise mock_exception

        with self.assertRaises(Exception):
            always_fails()
        
        self.assertEqual(call_count, 3)

    def test_no_retry_on_client_error(self):
        """Test that client errors (non-throttling) don't retry."""
        call_count = 0

        # Create a mock exception that looks like a client error
        mock_exception = Exception("AccessDenied")
        mock_exception.response = {'Error': {'Code': 'AccessDenied'}}

        @retry_on_failure(max_retries=3, delay=0.01)
        def client_error():
            nonlocal call_count
            call_count += 1
            raise mock_exception

        with self.assertRaises(Exception):
            client_error()
        
        # Should only be called once (no retry for client errors)
        self.assertEqual(call_count, 1)


class TestConfigurationConstants(unittest.TestCase):
    """Test that configuration constants are set correctly."""

    def test_group_name(self):
        """Test IAM group name is set."""
        self.assertEqual(GROUP_NAME, "StudentDataRestrictedAccess")

    def test_policy_arn(self):
        """Test policy ARN is valid format."""
        self.assertTrue(POLICY_ARN.startswith("arn:aws:iam::"))
        self.assertIn("AmazonS3ReadOnlyAccess", POLICY_ARN)

    def test_max_retries_positive(self):
        """Test max retries is a positive integer."""
        self.assertIsInstance(MAX_RETRIES, int)
        self.assertGreater(MAX_RETRIES, 0)

    def test_retry_delay_positive(self):
        """Test retry delay is a positive number."""
        self.assertIsInstance(RETRY_DELAY, (int, float))
        self.assertGreater(RETRY_DELAY, 0)


class TestUsernamePattern(unittest.TestCase):
    """Test the username regex pattern directly."""

    def test_pattern_matches_valid(self):
        """Test pattern matches valid usernames."""
        valid_names = [
            "user",
            "user123",
            "user_name",
            "user-name",
            "user.name",
            "user@domain",
            "user=value",
            "user,value",
            "A" * 64,
        ]
        for name in valid_names:
            with self.subTest(name=name):
                self.assertIsNotNone(USERNAME_PATTERN.match(name))

    def test_pattern_rejects_invalid(self):
        """Test pattern rejects invalid usernames."""
        invalid_names = [
            "",
            "A" * 65,
            "user name",
            "user!name",
            "user#name",
            "user$name",
            "user%name",
            "user^name",
            "user&name",
            "user*name",
            "user(name)",
            "user[name]",
            "user{name}",
        ]
        for name in invalid_names:
            with self.subTest(name=name):
                self.assertIsNone(USERNAME_PATTERN.match(name))


class TestIntegration(unittest.TestCase):
    """Integration tests for the provisioning workflow."""

    @patch('iam_provisioner.DEMO_MODE', True)
    def test_demo_mode_doesnt_call_aws(self):
        """Test that demo mode doesn't make real AWS calls."""
        # Import create_identity here to get the patched version
        from iam_provisioner import create_identity
        
        # In demo mode, should return True without AWS calls
        result = create_identity(None, "test_user")
        self.assertTrue(result)

    def test_invalid_username_returns_false(self):
        """Test that invalid usernames return False."""
        from iam_provisioner import create_identity
        
        result = create_identity(None, "")
        self.assertFalse(result)
        
        result = create_identity(None, "a" * 65)
        self.assertFalse(result)


class TestEdgeCases(unittest.TestCase):
    """Test edge cases and boundary conditions."""

    def test_username_boundary_63_chars(self):
        """Test username at 63 characters (one below max)."""
        self.assertTrue(validate_username("a" * 63))

    def test_username_boundary_64_chars(self):
        """Test username at exactly 64 characters (max)."""
        self.assertTrue(validate_username("a" * 64))

    def test_username_boundary_65_chars(self):
        """Test username at 65 characters (one above max)."""
        self.assertFalse(validate_username("a" * 65))

    def test_username_all_allowed_special_chars(self):
        """Test username using all allowed special characters."""
        # All allowed: alphanumeric plus =,.@-_
        self.assertTrue(validate_username("user=name,test.value@domain-name_final"))

    def test_username_unicode_rejected(self):
        """Test that unicode characters are rejected."""
        self.assertFalse(validate_username("usér"))
        self.assertFalse(validate_username("用户"))


if __name__ == '__main__':
    # Run tests with verbosity
    unittest.main(verbosity=2)

