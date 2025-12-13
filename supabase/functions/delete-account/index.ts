import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create Supabase client with service role key for admin operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Create regular client with the Authorization header to get current user
    // This way the client will use the token from the header automatically
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        },
        global: {
          headers: {
            Authorization: authHeader,
          },
        },
      }
    )

    // Get the current user - the client will use the Authorization header automatically
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      console.error('Error getting user:', userError)
      console.error('Auth header received:', authHeader ? 'present' : 'missing')
      return new Response(
        JSON.stringify({ 
          error: 'Invalid or expired token', 
          details: userError?.message || 'Could not authenticate user'
        }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log(`Attempting to delete account for user: ${user.id}`)

    const userId = user.id

    // Explicitly delete all related data before deleting the user
    // This ensures all data is removed even if CASCADE doesn't work as expected
    try {
      // Delete subscriptions
      const { error: subscriptionsError } = await supabaseAdmin
        .from('subscriptions')
        .delete()
        .eq('user_id', userId)
      
      if (subscriptionsError) {
        console.error('Error deleting subscriptions:', subscriptionsError)
        // Continue with deletion even if this fails
      } else {
        console.log(`Deleted subscriptions for user: ${userId}`)
      }

      // Delete appointments
      const { error: appointmentsError } = await supabaseAdmin
        .from('appointments')
        .delete()
        .eq('user_id', userId)
      
      if (appointmentsError) {
        console.error('Error deleting appointments:', appointmentsError)
        // Continue with deletion even if this fails
      } else {
        console.log(`Deleted appointments for user: ${userId}`)
      }

      // Delete tasks
      const { error: tasksError } = await supabaseAdmin
        .from('tasks')
        .delete()
        .eq('user_id', userId)
      
      if (tasksError) {
        console.error('Error deleting tasks:', tasksError)
        // Continue with deletion even if this fails
      } else {
        console.log(`Deleted tasks for user: ${userId}`)
      }

      // Delete user profile
      const { error: profileError } = await supabaseAdmin
        .from('user_profile')
        .delete()
        .eq('id', userId)
      
      if (profileError) {
        console.error('Error deleting user profile:', profileError)
        // Continue with deletion even if this fails (table might not exist)
      } else {
        console.log(`Deleted user profile for user: ${userId}`)
      }
    } catch (dataDeleteError) {
      console.error('Error deleting related data:', dataDeleteError)
      // Continue with user deletion even if data deletion fails
    }

    // Delete the user using admin client
    // This will also trigger CASCADE deletes as a backup
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (deleteError) {
      console.error('Error deleting user:', deleteError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to delete user account', 
          details: deleteError.message 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log(`Successfully deleted user account: ${userId}`)

    return new Response(
      JSON.stringify({ 
        message: 'Account deleted successfully',
        userId: user.id 
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})