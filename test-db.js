import { testConnection, getUserStats } from "./src/lib/db-debug.js";
import { initializeDatabase } from "./src/lib/database.js";

console.log("Testing database connection...");

async function runTests() {
  try {
    // Test basic connection
    const connectionOk = await testConnection();
    if (!connectionOk) {
      console.error("❌ Database connection failed");
      return;
    }
    console.log("✅ Database connection successful");

    // Initialize database
    await initializeDatabase();
    console.log("✅ Database initialized successfully");

    // Get user statistics
    const stats = await getUserStats();
    console.log("📊 User statistics:", stats);

    console.log("\n🎉 All database tests passed!");
  } catch (error) {
    console.error("❌ Database test failed:", error);
  } finally {
    process.exit(0);
  }
}

runTests();
