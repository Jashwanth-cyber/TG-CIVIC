import { useEffect, useState } from "react";
import { initializeDatabase } from "@/lib/database";

export const useDatabase = () => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [initError, setInitError] = useState<string | null>(null);

  useEffect(() => {
    const initialize = async () => {
      try {
        await initializeDatabase();
        setIsInitialized(true);
        console.log("Database connection established and tables initialized");
      } catch (error) {
        console.error("Failed to initialize database:", error);
        setInitError(error instanceof Error ? error.message : "Unknown error");
      }
    };

    initialize();
  }, []);

  return { isInitialized, initError };
};
