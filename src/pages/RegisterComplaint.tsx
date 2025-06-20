import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { createComplaint } from "@/lib/complaints";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  FileText,
  AlertCircle,
  CheckCircle,
  MapPin,
  Building2,
  Tag,
  AlertTriangle,
  Copy,
  Car,
  Droplets,
  Trash2,
  Zap,
  Lightbulb,
  Shield,
} from "lucide-react";

const RegisterComplaint = () => {
  const navigate = useNavigate();
  const { user } = useAuth();

  const [formData, setFormData] = useState({
    title: "",
    description: "",
    category: "",
    priority: "medium" as "low" | "medium" | "high" | "urgent",
    location: "",
    landmark: "",
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [showSuccessDialog, setShowSuccessDialog] = useState(false);
  const [complaintNumber, setComplaintNumber] = useState("");

  const categories = [
    {
      id: "Roads and Infrastructure",
      icon: <Car className="w-5 h-5" />,
      label: "Roads & Infrastructure",
    },
    {
      id: "Water Supply",
      icon: <Droplets className="w-5 h-5" />,
      label: "Water Supply",
    },
    {
      id: "Garbage Collection",
      icon: <Trash2 className="w-5 h-5" />,
      label: "Garbage Collection",
    },
    {
      id: "Electricity",
      icon: <Zap className="w-5 h-5" />,
      label: "Electricity",
    },
    {
      id: "Street Lights",
      icon: <Lightbulb className="w-5 h-5" />,
      label: "Street Lights",
    },
    {
      id: "Drainage and Sewerage",
      icon: <Shield className="w-5 h-5" />,
      label: "Drainage & Sewerage",
    },
    {
      id: "Public Transport",
      icon: <Car className="w-5 h-5" />,
      label: "Public Transport",
    },
    {
      id: "Parks and Recreation",
      icon: <Building2 className="w-5 h-5" />,
      label: "Parks & Recreation",
    },
    {
      id: "Building Permits",
      icon: <Building2 className="w-5 h-5" />,
      label: "Building Permits",
    },
    {
      id: "Noise Pollution",
      icon: <AlertTriangle className="w-5 h-5" />,
      label: "Noise Pollution",
    },
    {
      id: "Other",
      icon: <FileText className="w-5 h-5" />,
      label: "Other",
    },
  ];

  const getCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        const { latitude, longitude } = position.coords;
        setFormData({
          ...formData,
          location: `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`,
        });
      });
    }
  };

  const copyComplaintNumber = () => {
    navigator.clipboard.writeText(complaintNumber);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setIsLoading(true);

    if (
      !formData.title ||
      !formData.description ||
      !formData.category ||
      !formData.location
    ) {
      setError("Please fill in all required fields");
      setIsLoading(false);
      return;
    }

    if (!user || user.role !== "citizen") {
      setError("Only citizens can register complaints");
      setIsLoading(false);
      return;
    }

    try {
      console.log("🔄 Submitting complaint...");

      const complaint = await createComplaint(user.id, {
        title: formData.title,
        description: formData.description,
        category: formData.category,
        priority: formData.priority,
        location: formData.location,
        landmark: formData.landmark,
      });

      if (complaint) {
        setComplaintNumber(complaint.complaint_number);
        setShowSuccessDialog(true);

        // Reset form
        setFormData({
          title: "",
          description: "",
          category: "",
          priority: "medium",
          location: "",
          landmark: "",
        });
      } else {
        setError("Failed to register complaint. Please try again.");
      }
    } catch (error: any) {
      console.error("❌ Complaint registration error:", error);
      setError(
        error.message || "Failed to register complaint. Please try again.",
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleDialogClose = () => {
    setShowSuccessDialog(false);
    navigate("/track-complaint");
  };

  if (!user || user.role !== "citizen") {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50 flex items-center justify-center p-4">
        <Card className="w-full max-w-md">
          <CardContent className="pt-6">
            <div className="text-center">
              <AlertCircle className="mx-auto h-12 w-12 text-red-500 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Access Denied
              </h3>
              <p className="text-gray-600 mb-4">
                {!user
                  ? "Please log in as a citizen to register a complaint."
                  : "Only citizens can register complaints."}
              </p>
              <Button onClick={() => navigate("/login")}>Go to Login</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50">
      {/* Navigation */}
      <nav className="bg-white/95 backdrop-blur-md border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-700 rounded-lg flex items-center justify-center">
                <FileText className="w-6 h-6 text-white" />
              </div>
              <div>
                <span className="text-xl font-bold text-gray-900">
                  TG Civic
                </span>
                <span className="text-xs text-gray-600 ml-2">
                  Register Complaint
                </span>
              </div>
            </div>
            <Button variant="outline" onClick={() => navigate("/")}>
              Back to Home
            </Button>
          </div>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-700 rounded-xl flex items-center justify-center">
              <FileText className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Register Complaint
              </h1>
              <p className="text-gray-600">
                Submit your civic complaint for prompt resolution
              </p>
            </div>
          </div>

          {/* User Info */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <p className="text-sm text-blue-800">
              <strong>Logged in as:</strong> {user.name} ({user.email}) -{" "}
              {user.role}
            </p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Category Selection */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Tag className="w-5 h-5" />
                Issue Category
              </CardTitle>
              <CardDescription>
                Choose the category that best describes your complaint
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {categories.map((category) => (
                  <div
                    key={category.id}
                    className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                      formData.category === category.id
                        ? "border-blue-500 bg-blue-50"
                        : "border-gray-200 hover:border-gray-300"
                    }`}
                    onClick={() =>
                      setFormData({ ...formData, category: category.id })
                    }
                  >
                    <div className="flex flex-col items-center text-center space-y-2">
                      {category.icon}
                      <span className="text-sm font-medium">
                        {category.label}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Complaint Details */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="w-5 h-5" />
                Complaint Details
              </CardTitle>
              <CardDescription>
                Please provide detailed information about your complaint
              </CardDescription>
            </CardHeader>
            <CardContent>
              {error && (
                <Alert variant="destructive" className="mb-4">
                  <AlertCircle className="h-4 w-4" />
                  <AlertDescription>{error}</AlertDescription>
                </Alert>
              )}

              <div className="space-y-4">
                {/* Title */}
                <div>
                  <Label htmlFor="title">
                    Complaint Title <span className="text-red-500">*</span>
                  </Label>
                  <Input
                    id="title"
                    placeholder="Brief title of your complaint"
                    value={formData.title}
                    onChange={(e) =>
                      setFormData({ ...formData, title: e.target.value })
                    }
                    required
                  />
                </div>

                {/* Priority */}
                <div>
                  <Label htmlFor="priority">Priority Level</Label>
                  <Select
                    value={formData.priority}
                    onValueChange={(
                      value: "low" | "medium" | "high" | "urgent",
                    ) => setFormData({ ...formData, priority: value })}
                  >
                    <SelectTrigger>
                      <div className="flex items-center gap-2">
                        <AlertTriangle className="h-4 w-4 text-gray-400" />
                        <SelectValue />
                      </div>
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="low">🟢 Low Priority</SelectItem>
                      <SelectItem value="medium">🟡 Medium Priority</SelectItem>
                      <SelectItem value="high">🟠 High Priority</SelectItem>
                      <SelectItem value="urgent">🔴 Urgent</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Description */}
                <div>
                  <Label htmlFor="description">
                    Detailed Description <span className="text-red-500">*</span>
                  </Label>
                  <Textarea
                    id="description"
                    placeholder="Provide detailed description of the issue..."
                    value={formData.description}
                    onChange={(e) =>
                      setFormData({ ...formData, description: e.target.value })
                    }
                    rows={5}
                    required
                  />
                  <p className="text-sm text-gray-500 mt-1">
                    Please be as specific as possible to help us understand and
                    resolve your complaint quickly.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Location Details */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="w-5 h-5" />
                Location Information
              </CardTitle>
              <CardDescription>
                Help us locate the issue precisely
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {/* Location */}
                <div>
                  <Label htmlFor="location">
                    Location/Address <span className="text-red-500">*</span>
                  </Label>
                  <div className="flex space-x-2">
                    <Input
                      id="location"
                      placeholder="Complete address or coordinates"
                      value={formData.location}
                      onChange={(e) =>
                        setFormData({ ...formData, location: e.target.value })
                      }
                      className="flex-1"
                      required
                    />
                    <Button
                      type="button"
                      variant="outline"
                      onClick={getCurrentLocation}
                    >
                      <MapPin className="w-4 h-4 mr-2" />
                      Current Location
                    </Button>
                  </div>
                </div>

                {/* Landmark */}
                <div>
                  <Label htmlFor="landmark">Nearby Landmark</Label>
                  <div className="relative">
                    <Building2 className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                    <Input
                      id="landmark"
                      placeholder="Nearby landmark, building, or shop"
                      value={formData.landmark}
                      onChange={(e) =>
                        setFormData({ ...formData, landmark: e.target.value })
                      }
                      className="pl-10"
                    />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Submit Button */}
          <Card>
            <CardContent className="pt-6">
              <div className="flex gap-4">
                <Button
                  type="submit"
                  className="flex-1 bg-blue-600 hover:bg-blue-700"
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                      Registering Complaint...
                    </>
                  ) : (
                    <>
                      <FileText className="w-4 h-4 mr-2" />
                      Register Complaint
                    </>
                  )}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => navigate("/")}
                >
                  Cancel
                </Button>
              </div>
            </CardContent>
          </Card>
        </form>
      </div>

      {/* Success Dialog */}
      <Dialog open={showSuccessDialog} onOpenChange={handleDialogClose}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-green-600">
              <CheckCircle className="w-6 h-6" />
              Complaint Registered Successfully!
            </DialogTitle>
            <DialogDescription>
              Your complaint has been registered and assigned a tracking number.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="bg-gray-50 rounded-lg p-4">
              <Label className="text-sm font-medium text-gray-700">
                Your Complaint Number
              </Label>
              <div className="flex items-center justify-between mt-2">
                <span className="font-mono text-lg font-bold text-blue-600">
                  {complaintNumber}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={copyComplaintNumber}
                  className="ml-2"
                >
                  <Copy className="w-4 h-4 mr-1" />
                  Copy
                </Button>
              </div>
            </div>
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <div className="flex items-start space-x-3">
                <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5" />
                <div className="flex-1">
                  <h4 className="font-medium text-blue-800">Important Notes</h4>
                  <ul className="text-sm text-blue-700 mt-1 space-y-1">
                    <li>• Save this number to track your complaint status</li>
                    <li>• You can check updates using this number</li>
                    <li>• Expected resolution within 3-7 working days</li>
                  </ul>
                </div>
              </div>
            </div>
            <div className="flex space-x-3">
              <Button
                onClick={() => navigate("/track-complaint")}
                className="flex-1"
              >
                Track Complaint
              </Button>
              <Button
                variant="outline"
                onClick={() => navigate("/")}
                className="flex-1"
              >
                Go Home
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default RegisterComplaint;
