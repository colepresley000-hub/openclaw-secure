#!/usr/bin/env python3
"""
ShieldClaw Stripe Payment Integration

Handles subscription creation, management, and webhooks.
"""

import os
import stripe
from datetime import datetime
from typing import Dict, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('ShieldClaw.Payments')

# Configure Stripe
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
STRIPE_WEBHOOK_SECRET = os.getenv('STRIPE_WEBHOOK_SECRET')


class PaymentManager:
    """Manages Stripe subscriptions and payments"""
    
    # Product IDs (create these in Stripe Dashboard)
    PRODUCTS = {
        'monitor': {
            'name': 'ShieldClaw Monitor',
            'price_id_monthly': os.getenv('STRIPE_MONITOR_PRICE_ID'),
            'price': 7900,  # $79.00 in cents
        },
        'enterprise': {
            'name': 'ShieldClaw Enterprise',
            'custom_pricing': True
        }
    }
    
    def create_customer(self, email: str, name: str, metadata: Optional[Dict] = None) -> Dict:
        """Create a new Stripe customer"""
        try:
            customer = stripe.Customer.create(
                email=email,
                name=name,
                metadata=metadata or {}
            )
            
            logger.info(f"Created customer: {customer.id} ({email})")
            return {
                'success': True,
                'customer_id': customer.id,
                'customer': customer
            }
            
        except stripe.error.StripeError as e:
            logger.error(f"Error creating customer: {e}")
            return {'success': False, 'error': str(e)}
    
    def create_checkout_session(
        self,
        customer_email: str,
        price_id: str,
        success_url: str,
        cancel_url: str,
        trial_days: int = 14,
        metadata: Optional[Dict] = None
    ) -> Dict:
        """Create a Stripe Checkout session for subscription"""
        try:
            session = stripe.checkout.Session.create(
                customer_email=customer_email,
                mode='subscription',
                payment_method_types=['card'],
                line_items=[{
                    'price': price_id,
                    'quantity': 1,
                }],
                subscription_data={
                    'trial_period_days': trial_days,
                    'metadata': metadata or {}
                },
                success_url=success_url + '?session_id={CHECKOUT_SESSION_ID}',
                cancel_url=cancel_url,
            )
            
            logger.info(f"Created checkout session: {session.id}")
            return {
                'success': True,
                'session_id': session.id,
                'session_url': session.url
            }
            
        except stripe.error.StripeError as e:
            logger.error(f"Error creating checkout session: {e}")
            return {'success': False, 'error': str(e)}
    
    def create_portal_session(self, customer_id: str, return_url: str) -> Dict:
        """Create a customer portal session for subscription management"""
        try:
            session = stripe.billing_portal.Session.create(
                customer=customer_id,
                return_url=return_url,
            )
            
            return {
                'success': True,
                'portal_url': session.url
            }
            
        except stripe.error.StripeError as e:
            logger.error(f"Error creating portal session: {e}")
            return {'success': False, 'error': str(e)}
    
    def get_subscription(self, subscription_id: str) -> Dict:
        """Get subscription details"""
        try:
            subscription = stripe.Subscription.retrieve(subscription_id)
            
            return {
                'success': True,
                'subscription': subscription,
                'status': subscription.status,
                'current_period_end': datetime.fromtimestamp(subscription.current_period_end),
                'cancel_at_period_end': subscription.cancel_at_period_end
            }
            
        except stripe.error.StripeError as e:
            logger.error(f"Error retrieving subscription: {e}")
            return {'success': False, 'error': str(e)}
    
    def cancel_subscription(self, subscription_id: str, immediately: bool = False) -> Dict:
        """Cancel a subscription"""
        try:
            if immediately:
                subscription = stripe.Subscription.delete(subscription_id)
            else:
                subscription = stripe.Subscription.modify(
                    subscription_id,
                    cancel_at_period_end=True
                )
            
            logger.info(f"Cancelled subscription: {subscription_id}")
            return {'success': True, 'subscription': subscription}
            
        except stripe.error.StripeError as e:
            logger.error(f"Error cancelling subscription: {e}")
            return {'success': False, 'error': str(e)}
    
    def handle_webhook(self, payload: bytes, signature: str) -> Dict:
        """Handle Stripe webhook events"""
        try:
            event = stripe.Webhook.construct_event(
                payload, signature, STRIPE_WEBHOOK_SECRET
            )
            
        except ValueError as e:
            logger.error(f"Invalid webhook payload: {e}")
            return {'success': False, 'error': 'Invalid payload'}
        except stripe.error.SignatureVerificationError as e:
            logger.error(f"Invalid webhook signature: {e}")
            return {'success': False, 'error': 'Invalid signature'}
        
        # Handle different event types
        event_type = event['type']
        event_data = event['data']['object']
        
        logger.info(f"Received webhook: {event_type}")
        
        if event_type == 'checkout.session.completed':
            # Payment successful, activate subscription
            self._handle_successful_checkout(event_data)
        
        elif event_type == 'customer.subscription.created':
            # New subscription created
            self._handle_subscription_created(event_data)
        
        elif event_type == 'customer.subscription.updated':
            # Subscription updated (e.g., plan change, cancellation)
            self._handle_subscription_updated(event_data)
        
        elif event_type == 'customer.subscription.deleted':
            # Subscription ended
            self._handle_subscription_deleted(event_data)
        
        elif event_type == 'invoice.payment_failed':
            # Payment failed
            self._handle_payment_failed(event_data)
        
        return {'success': True, 'event_type': event_type}
    
    def _handle_successful_checkout(self, session_data: Dict):
        """Handle successful checkout"""
        customer_id = session_data.get('customer')
        subscription_id = session_data.get('subscription')
        
        logger.info(f"Successful checkout: customer={customer_id}, subscription={subscription_id}")
        
        # TODO: Activate user's Monitor access in your database
        # TODO: Send welcome email
    
    def _handle_subscription_created(self, subscription_data: Dict):
        """Handle subscription creation"""
        subscription_id = subscription_data['id']
        customer_id = subscription_data['customer']
        status = subscription_data['status']
        
        logger.info(f"Subscription created: {subscription_id}, status={status}")
        
        # TODO: Update user record in database
    
    def _handle_subscription_updated(self, subscription_data: Dict):
        """Handle subscription update"""
        subscription_id = subscription_data['id']
        status = subscription_data['status']
        cancel_at_period_end = subscription_data.get('cancel_at_period_end', False)
        
        logger.info(f"Subscription updated: {subscription_id}, status={status}, cancel={cancel_at_period_end}")
        
        # TODO: Update user access based on status
        if status == 'active':
            # Ensure user has access
            pass
        elif status in ['canceled', 'unpaid']:
            # Revoke access
            pass
    
    def _handle_subscription_deleted(self, subscription_data: Dict):
        """Handle subscription deletion"""
        subscription_id = subscription_data['id']
        
        logger.info(f"Subscription deleted: {subscription_id}")
        
        # TODO: Revoke user's Monitor access
        # TODO: Send cancellation confirmation email
    
    def _handle_payment_failed(self, invoice_data: Dict):
        """Handle failed payment"""
        customer_id = invoice_data.get('customer')
        subscription_id = invoice_data.get('subscription')
        
        logger.warning(f"Payment failed: customer={customer_id}, subscription={subscription_id}")
        
        # TODO: Send payment failure notification
        # TODO: Optionally suspend access after grace period


def create_stripe_products():
    """Helper function to create products in Stripe (run once)"""
    try:
        # Create Monitor product
        monitor_product = stripe.Product.create(
            name='ShieldClaw Monitor',
            description='24/7 runtime security monitoring for OpenClaw',
        )
        
        # Create Monitor price (monthly)
        monitor_price = stripe.Price.create(
            product=monitor_product.id,
            unit_amount=7900,  # $79.00
            currency='usd',
            recurring={'interval': 'month'},
        )
        
        print(f"Created Monitor product: {monitor_product.id}")
        print(f"Created Monitor price: {monitor_price.id}")
        print(f"\nAdd to .env:")
        print(f"STRIPE_MONITOR_PRICE_ID={monitor_price.id}")
        
    except stripe.error.StripeError as e:
        print(f"Error creating products: {e}")


def main():
    """Example usage"""
    import argparse
    
    parser = argparse.ArgumentParser(description='ShieldClaw Payment Manager')
    parser.add_argument('--setup-products', action='store_true', help='Create Stripe products')
    parser.add_argument('--test-checkout', help='Test checkout with email')
    
    args = parser.parse_args()
    
    if args.setup_products:
        create_stripe_products()
    
    elif args.test_checkout:
        pm = PaymentManager()
        result = pm.create_checkout_session(
            customer_email=args.test_checkout,
            price_id=os.getenv('STRIPE_MONITOR_PRICE_ID'),
            success_url='https://shieldclaw.xyz/success',
            cancel_url='https://shieldclaw.xyz/pricing',
            trial_days=14
        )
        
        if result['success']:
            print(f"Checkout URL: {result['session_url']}")
        else:
            print(f"Error: {result['error']}")


if __name__ == '__main__':
    main()
