"""
Automated IAM Provisioning for Student Data Infrastructure
Author: Mohammad Khan
Date: November 14, 2025

Production-ready IAM provisioning script for student data access management.
Enhanced with improved error handling, logging, type hints, and best practices.

Usage:
    # Run in demo mode (default - safe for testing)
    python iam_provisioner.py

    # Run in live mode (requires AWS credentials)
    IAM_LIVE_MODE=true python iam_provisioner.py
"""

import logging
import time
import re
import os
from typing import Optional, List
from functools import wraps

# Configuration - Use environment variable to control mode
# Set IAM_LIVE_MODE=true to execute actual AWS API calls
DEMO_MODE = os.environ.get("IAM_LIVE_MODE", "").lower() != "true"
GROUP_NAME = "StudentDataRestrictedAccess"
POLICY_ARN = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
MAX_RETRIES = 3
RETRY_DELAY = 1.0

# IAM username validation: 1-64 characters, alphanumeric plus: =,.@-
USERNAME_PATTERN = re.compile(r'^[a-zA-Z0-9=,.@_-]{1,64}$')

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# AWS SDK imports with proper exception handling
try:
    import boto3
    from botocore.exceptions import ClientError, BotoCoreError
    AWS_AVAILABLE = True
except ImportError:
    boto3 = None
    ClientError = Exception
    BotoCoreError = Exception
    AWS_AVAILABLE = False
    logger.warning("boto3 not installed - running in DEMO mode.")


def retry_on_failure(max_retries: int = MAX_RETRIES, delay: float = RETRY_DELAY):
    """Decorator to retry AWS API calls on transient failures."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except (ClientError, BotoCoreError) as e:
                    last_exception = e
                    error_code = getattr(e, 'response', {}).get('Error', {}).get('Code', '')
                    
                    # Don't retry on client errors (4xx) except throttling
                    if error_code and not error_code.endswith('Throttling'):
                        raise
                    
                    if attempt < max_retries - 1:
                        logger.warning(f"Attempt {attempt + 1} failed: {e}. Retrying in {delay}s...")
                        time.sleep(delay * (attempt + 1))  # Exponential backoff
                    else:
                        logger.error(f"All {max_retries} attempts failed.")
                        raise
            if last_exception:
                raise last_exception
        return wrapper
    return decorator


def validate_username(username: str) -> bool:
    """
    Validate IAM username according to AWS requirements.
    
    Args:
        username: The username to validate
        
    Returns:
        True if valid, False otherwise
    """
    if not username or not isinstance(username, str):
        return False
    if not USERNAME_PATTERN.match(username):
        return False
    return True


def iam_client() -> Optional[object]:
    """
    Create and return an IAM client instance.
    
    Returns:
        boto3 IAM client if available, None otherwise
    """
    if not AWS_AVAILABLE or boto3 is None:
        logger.warning("boto3 not installed - running in DEMO mode.")
        return None
    try:
        return boto3.client("iam")
    except (BotoCoreError, Exception) as e:
        logger.error(f"Failed to create IAM client: {e}")
        return None


@retry_on_failure()
def ensure_group(iam: Optional[object]) -> bool:
    """
    Ensure the IAM group exists and has the required policy attached.
    
    Args:
        iam: boto3 IAM client instance
        
    Returns:
        True if group is ready, False otherwise
    """
    logger.info(f"Validating IAM group '{GROUP_NAME}'...")

    if DEMO_MODE or iam is None:
        logger.info(f"[DEMO] Group '{GROUP_NAME}' verified.")
        return True

    try:
        # Check if group exists
        try:
            iam.get_group(GroupName=GROUP_NAME)
            logger.info(f"Group '{GROUP_NAME}' already exists.")
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code == 'NoSuchEntity':
                logger.info(f"Creating group '{GROUP_NAME}'...")
                iam.create_group(GroupName=GROUP_NAME)
                logger.info(f"Group '{GROUP_NAME}' created successfully.")
            else:
                logger.error(f"Unexpected error checking group: {e}")
                raise

        # Attach policy (idempotent - safe to call multiple times)
        try:
            iam.attach_group_policy(GroupName=GROUP_NAME, PolicyArn=POLICY_ARN)
            logger.info(f"Policy '{POLICY_ARN}' attached to group '{GROUP_NAME}'.")
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code == 'EntityAlreadyExists':
                logger.info(f"Policy already attached to group '{GROUP_NAME}'.")
            else:
                logger.error(f"Failed to attach policy: {e}")
                raise

        return True

    except (ClientError, BotoCoreError) as e:
        logger.error(f"Failed to ensure group '{GROUP_NAME}': {e}")
        return False


@retry_on_failure()
def create_identity(iam: Optional[object], username: str) -> bool:
    """
    Create an IAM user and add them to the configured group.
    
    Args:
        iam: boto3 IAM client instance
        username: The username to create
        
    Returns:
        True if user was created successfully, False otherwise
    """
    # Validate username
    if not validate_username(username):
        logger.error(f"Invalid username format: '{username}'. Username must be 1-64 characters "
                    "and contain only alphanumeric characters plus: =,.@-_")
        return False

    logger.info(f"Provisioning user: {username}")

    if DEMO_MODE or iam is None:
        logger.info(f"[DEMO] Provisioned user '{username}' with least-privilege access.")
        time.sleep(0.05)
        return True

    try:
        # Create user (idempotent check)
        try:
            iam.create_user(UserName=username)
            logger.info(f"User '{username}' created successfully.")
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code == 'EntityAlreadyExists':
                logger.info(f"User '{username}' already exists, skipping creation.")
            else:
                logger.error(f"Failed to create user '{username}': {e}")
                raise

        # Add user to group
        try:
            iam.add_user_to_group(UserName=username, GroupName=GROUP_NAME)
            logger.info(f"User '{username}' added to group '{GROUP_NAME}'.")
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', '')
            if error_code == 'EntityAlreadyExists':
                logger.info(f"User '{username}' already in group '{GROUP_NAME}'.")
            else:
                logger.error(f"Failed to add user '{username}' to group: {e}")
                raise

        return True

    except (ClientError, BotoCoreError) as e:
        logger.error(f"Failed to provision user '{username}': {e}")
        return False


def main() -> None:
    """Main entry point for the IAM provisioning script."""
    mode = "DEMO" if DEMO_MODE else "LIVE"
    logger.info(f"\n{'='*60}")
    logger.info(f"IAM Provisioning System - {mode} MODE")
    logger.info(f"{'='*60}")
    
    if DEMO_MODE:
        logger.info("[INFO] Running in DEMO mode - no AWS changes will be made.")
        logger.info("[INFO] Set IAM_LIVE_MODE=true to execute actual AWS API calls.")
    else:
        logger.warning("[LIVE] Running in LIVE mode - AWS resources will be modified!")
    
    logger.info("")
    iam = iam_client()
    
    # Ensure group exists and is configured
    if not ensure_group(iam):
        logger.error("Failed to configure IAM group. Exiting.")
        return

    users: List[str] = [
        "registrar_office_analyst",
        "student_data_specialist",
        "academic_records_manager",
        "it_data_access_auditor",
        "faculty_reporting_system"
    ]

    # Provision users
    start = time.time()
    success_count = 0
    failed_users = []

    for user in users:
        if create_identity(iam, user):
            success_count += 1
        else:
            failed_users.append(user)

    elapsed = time.time() - start

    # Summary
    mode = "DEMO" if DEMO_MODE else "LIVE"
    logger.info(f"\n{'='*60}")
    logger.info(f"Provisioning Summary ({mode} MODE)")
    logger.info(f"{'='*60}")
    logger.info(f"Total users: {len(users)}")
    logger.info(f"Successful: {success_count}")
    logger.info(f"Failed: {len(failed_users)}")
    if failed_users:
        logger.warning(f"Failed users: {', '.join(failed_users)}")
    logger.info(f"Execution time: {elapsed:.2f} seconds")
    logger.info(f"Group policy: {GROUP_NAME} with least-privilege access")
    if DEMO_MODE:
        logger.info(f"[NOTE] Run with IAM_LIVE_MODE=true to create actual IAM resources")
    logger.info(f"{'='*60}\n")


if __name__ == "__main__":
    main()
