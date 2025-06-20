import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
} from "react";
import { initializeDatabase } from "@/lib/database";
import {
  loginUser,
  registerUser,
  getUserById,
  updateUserProfile,
} from "@/lib/auth";

export interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: "citizen" | "admin" | "official";
  department?: string;
  createdAt: string;
  lastLogin: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<boolean>;
  register: (userData: {
    name: string;
    email: string;
    phone: string;
    password: string;
    role: "citizen" | "admin";
  }) => Promise<boolean>;
  logout: () => void;
  updateProfile: (updates: Partial<User>) => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Initialize database and load user from localStorage on mount
  useEffect(() => {
    const initializeApp = async () => {
      try {
        // Initialize database tables and default users
        await initializeDatabase();

        // Load user from localStorage
        const savedUser = localStorage.getItem("tg-civic-user");
        if (savedUser) {
          try {
            const userData = JSON.parse(savedUser);
            // Verify user still exists in database
            const dbUser = await getUserById(userData.id);
            if (dbUser) {
              setUser(dbUser);
            } else {
              localStorage.removeItem("tg-civic-user");
            }
          } catch (error) {
            console.error("Error loading user from localStorage:", error);
            localStorage.removeItem("tg-civic-user");
          }
        }
      } catch (error) {
        console.error("Error initializing app:", error);
      } finally {
        setIsLoading(false);
      }
    };

    initializeApp();
  }, []);

  // Save user to localStorage whenever user changes
  useEffect(() => {
    if (user) {
      localStorage.setItem("tg-civic-user", JSON.stringify(user));
    } else {
      localStorage.removeItem("tg-civic-user");
    }
  }, [user]);

  const login = async (email: string, password: string): Promise<boolean> => {
    setIsLoading(true);

    try {
      const loggedInUser = await loginUser({ email, password });

      if (loggedInUser) {
        setUser(loggedInUser);
        return true;
      }

      return false;
    } catch (error) {
      console.error("Login error:", error);
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (userData: {
    name: string;
    email: string;
    phone: string;
    password: string;
    role: "citizen" | "admin";
  }): Promise<boolean> => {
    setIsLoading(true);

    try {
      const newUser = await registerUser(userData);

      if (newUser) {
        setUser(newUser);
        return true;
      }

      return false;
    } catch (error) {
      console.error("Registration error:", error);
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem("tg-civic-user");
    // Force redirect to homepage after logout
    if (typeof window !== "undefined") {
      window.location.href = "/";
    }
  };

  const updateProfile = async (updates: Partial<User>): Promise<boolean> => {
    if (!user) return false;

    try {
      const updatedUser = await updateUserProfile(user.id, updates);
      if (updatedUser) {
        setUser(updatedUser);
        return true;
      }
      return false;
    } catch (error) {
      console.error("Update profile error:", error);
      return false;
    }
  };

  const value: AuthContextType = {
    user,
    isAuthenticated: !!user,
    isLoading,
    login,
    register,
    logout,
    updateProfile,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
