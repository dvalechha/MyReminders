#!/bin/bash

# Deploy Edge Function Script for Account Deletion Fix
# This script helps deploy the delete-account Edge Function to Supabase

set -e  # Exit on any error

echo "🚀 Deploying Account Deletion Edge Function"
echo "=========================================="

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Installing..."
    if command -v npm &> /dev/null; then
        npm install -g supabase
    else
        echo "❌ npm not found. Please install Node.js and npm first."
        echo "Visit: https://nodejs.org/"
        exit 1
    fi
fi

echo "✅ Supabase CLI found"

# Check if user is logged in
if ! supabase projects list &> /dev/null; then
    echo "🔑 Please log in to Supabase:"
    supabase login
fi

echo "✅ Logged in to Supabase"

# List projects to help user identify their project
echo ""
echo "📋 Your Supabase projects:"
supabase projects list

echo ""
read -p "🏗️  Enter your project reference ID: " sutjrivsvzikhibqwvqu

if [ -z "$sutjrivsvzikhibqwvqu" ]; then
    echo "❌ Project reference is required"
    exit 1
fi

# Link to the project
echo "🔗 Linking to project $sutjrivsvzikhibqwvqu..."
supabase link --project-ref "$sutjrivsvzikhibqwvqu"

echo "✅ Project linked successfully"

# Deploy the Edge Function
echo ""
echo "📦 Deploying delete-account Edge Function..."
supabase functions deploy delete-account

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Edge Function deployed successfully!"
    echo ""
    echo "📊 Checking deployment status..."
    supabase functions list
    
    echo ""
    echo "✅ Account deletion fix is now live!"
    echo ""
    echo "🧪 Next Steps:"
    echo "1. Test the account deletion feature in your Flutter app"
    echo "2. Verify data is properly deleted from Supabase dashboard"
    echo "3. Check function logs if you encounter any issues:"
    echo "   supabase functions logs delete-account"
    echo ""
    echo "📖 For detailed setup instructions, see ACCOUNT_DELETION_SETUP.md"
else
    echo "❌ Deployment failed. Check the error messages above."
    echo "💡 Common issues:"
    echo "   - Network connectivity"
    echo "   - Project permissions"
    echo "   - Invalid project reference"
    exit 1
fi