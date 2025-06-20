import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { getCitizenComplaints, type Complaint } from "@/lib/complaints";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Search,
  Clock,
  CheckCircle,
  AlertCircle,
  FileText,
  MapPin,
  Calendar,
  User,
  Building2,
  Eye,
  Phone,
  Mail,
  History,
  XCircle,
  RefreshCw,
  Plus,
} from "lucide-react";

const TrackComplaint = () => {
  const navigate = useNavigate();
  const { user } = useAuth();

  const [complaints, setComplaints] = useState<Complaint[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [selectedComplaint, setSelectedComplaint] = useState<Complaint | null>(
    null,
  );
  const [hasSearched, setHasSearched] = useState(false);

  const fetchComplaints = async () => {
    if (!user || user.role !== "citizen") {
      setError("Please log in as a citizen to track complaints");
      return;
    }

    try {
      setIsLoading(true);
      setError("");
      const citizenComplaints = await getCitizenComplaints(parseInt(user.id));
      setComplaints(citizenComplaints);
      setHasSearched(true);
    } catch (error: any) {
      console.error("❌ Error fetching complaints:", error);
      setError(error.message || "Failed to fetch complaints");
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      pending: {
        label: "Pending",
        variant: "secondary" as const,
        icon: <Clock className="w-3 h-3" />,
      },
      in_progress: {
        label: "In Progress",
        variant: "default" as const,
        icon: <RefreshCw className="w-3 h-3" />,
      },
      resolved: {
        label: "Resolved",
        variant: "success" as const,
        icon: <CheckCircle className="w-3 h-3" />,
      },
      rejected: {
        label: "Rejected",
        variant: "destructive" as const,
        icon: <XCircle className="w-3 h-3" />,
      },
    };
    const config =
      statusConfig[status as keyof typeof statusConfig] || statusConfig.pending;
    return (
      <Badge variant={config.variant} className="flex items-center gap-1">
        {config.icon}
        {config.label}
      </Badge>
    );
  };

  const getPriorityBadge = (priority: string) => {
    const priorityConfig = {
      low: { label: "🟢 Low", variant: "secondary" as const },
      medium: { label: "🟡 Medium", variant: "default" as const },
      high: { label: "🟠 High", variant: "destructive" as const },
      urgent: { label: "🔴 Urgent", variant: "destructive" as const },
    };
    const config =
      priorityConfig[priority as keyof typeof priorityConfig] ||
      priorityConfig.medium;
    return <Badge variant={config.variant}>{config.label}</Badge>;
  };

  const getStatusColor = (status: string) => {
    const colors = {
      pending: "bg-orange-100 border-orange-300",
      in_progress: "bg-blue-100 border-blue-300",
      resolved: "bg-green-100 border-green-300",
      rejected: "bg-red-100 border-red-300",
    };
    return colors[status as keyof typeof colors] || colors.pending;
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
                  ? "Please log in as a citizen to track complaints."
                  : "Only citizens can track complaints."}
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
                <Search className="w-6 h-6 text-white" />
              </div>
              <div>
                <span className="text-xl font-bold text-gray-900">
                  TG Civic
                </span>
                <span className="text-xs text-gray-600 ml-2">
                  Track Complaints
                </span>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <Button
                variant="outline"
                onClick={() => navigate("/register-complaint")}
              >
                <Plus className="w-4 h-4 mr-2" />
                New Complaint
              </Button>
              <Button variant="outline" onClick={() => navigate("/")}>
                Back to Home
              </Button>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-700 rounded-xl flex items-center justify-center">
              <Search className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Track Your Complaints
              </h1>
              <p className="text-gray-600">
                View the status and progress of your submitted complaints
              </p>
            </div>
          </div>

          {/* User Info */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <p className="text-sm text-blue-800">
              <strong>Logged in as:</strong> {user.name} ({user.email})
            </p>
          </div>
        </div>

        {/* Search Section */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="w-5 h-5" />
              Your Complaints
            </CardTitle>
            <CardDescription>
              Load and view all your submitted complaints
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-4">
              <Button onClick={fetchComplaints} disabled={isLoading}>
                {isLoading ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Loading...
                  </>
                ) : (
                  <>
                    <Search className="w-4 h-4 mr-2" />
                    Load My Complaints
                  </>
                )}
              </Button>
              {hasSearched && (
                <p className="text-sm text-gray-600">
                  Found {complaints.length} complaint(s)
                </p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Error Display */}
        {error && (
          <Alert variant="destructive" className="mb-6">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {/* Results */}
        {hasSearched && (
          <div className="space-y-6">
            {complaints.length === 0 ? (
              <Card>
                <CardContent className="pt-6">
                  <div className="text-center py-8">
                    <FileText className="mx-auto h-16 w-16 text-gray-400 mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">
                      No Complaints Found
                    </h3>
                    <p className="text-gray-600 mb-4">
                      You haven't registered any complaints yet.
                    </p>
                    <Button onClick={() => navigate("/register-complaint")}>
                      <Plus className="w-4 h-4 mr-2" />
                      Register Your First Complaint
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ) : (
              <div className="grid gap-6">
                <div className="flex items-center justify-between">
                  <h2 className="text-xl font-semibold text-gray-900">
                    Your Complaints ({complaints.length})
                  </h2>
                  <Button variant="outline" onClick={fetchComplaints} size="sm">
                    <RefreshCw className="w-4 h-4 mr-2" />
                    Refresh
                  </Button>
                </div>

                {complaints.map((complaint) => (
                  <Card
                    key={complaint.id}
                    className={`border-l-4 ${getStatusColor(complaint.status)}`}
                  >
                    <CardHeader>
                      <div className="flex items-start justify-between">
                        <div className="space-y-2">
                          <div className="flex items-center gap-3">
                            <CardTitle className="text-lg">
                              {complaint.title}
                            </CardTitle>
                            {getStatusBadge(complaint.status)}
                            {getPriorityBadge(complaint.priority)}
                          </div>
                          <p className="text-sm text-gray-600 font-mono">
                            #{complaint.complaint_number}
                          </p>
                        </div>
                        <Dialog>
                          <DialogTrigger asChild>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => setSelectedComplaint(complaint)}
                            >
                              <Eye className="w-4 h-4 mr-2" />
                              View Details
                            </Button>
                          </DialogTrigger>
                          <ComplaintDetailsDialog
                            complaint={selectedComplaint}
                          />
                        </Dialog>
                      </div>
                    </CardHeader>
                    <CardContent>
                      <div className="grid md:grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <div className="flex items-center gap-2 text-sm">
                            <Building2 className="w-4 h-4 text-gray-400" />
                            <span className="font-medium">Category:</span>
                            <span>{complaint.category}</span>
                          </div>
                          <div className="flex items-start gap-2 text-sm">
                            <MapPin className="w-4 h-4 text-gray-400 mt-0.5" />
                            <div>
                              <span className="font-medium">Location:</span>
                              <p className="text-gray-600">
                                {complaint.location}
                              </p>
                              {complaint.landmark && (
                                <p className="text-gray-500 text-xs">
                                  Near: {complaint.landmark}
                                </p>
                              )}
                            </div>
                          </div>
                        </div>
                        <div className="space-y-2">
                          <div className="flex items-center gap-2 text-sm">
                            <Calendar className="w-4 h-4 text-gray-400" />
                            <span className="font-medium">Registered:</span>
                            <span>
                              {new Date(
                                complaint.created_at,
                              ).toLocaleDateString()}
                            </span>
                          </div>
                          <div className="flex items-center gap-2 text-sm">
                            <History className="w-4 h-4 text-gray-400" />
                            <span className="font-medium">Last Updated:</span>
                            <span>
                              {new Date(
                                complaint.updated_at,
                              ).toLocaleDateString()}
                            </span>
                          </div>
                        </div>
                      </div>
                      <div className="mt-4">
                        <p className="text-sm text-gray-700 line-clamp-2">
                          {complaint.description}
                        </p>
                      </div>
                      {complaint.admin_notes && (
                        <div className="mt-4 p-3 bg-gray-50 rounded-lg">
                          <div className="flex items-center gap-2 mb-2">
                            <User className="w-4 h-4 text-gray-500" />
                            <span className="text-sm font-medium text-gray-700">
                              Admin Notes:
                            </span>
                          </div>
                          <p className="text-sm text-gray-600">
                            {complaint.admin_notes}
                          </p>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

// Complaint Details Dialog Component
const ComplaintDetailsDialog = ({
  complaint,
}: {
  complaint: Complaint | null;
}) => {
  if (!complaint) return null;

  return (
    <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
      <DialogHeader>
        <DialogTitle className="flex items-center gap-2">
          <FileText className="w-5 h-5" />
          Complaint Details - {complaint.complaint_number}
        </DialogTitle>
        <DialogDescription>
          Complete information about your complaint
        </DialogDescription>
      </DialogHeader>

      <div className="space-y-6">
        {/* Status and Priority */}
        <div className="flex items-center gap-4">
          <div>
            <Label className="text-sm font-medium text-gray-700">Status</Label>
            <div className="mt-1">
              <Badge
                variant={
                  complaint.status === "resolved"
                    ? "success"
                    : complaint.status === "rejected"
                      ? "destructive"
                      : "secondary"
                }
              >
                {complaint.status === "pending" && (
                  <Clock className="w-3 h-3 mr-1" />
                )}
                {complaint.status === "in_progress" && (
                  <RefreshCw className="w-3 h-3 mr-1" />
                )}
                {complaint.status === "resolved" && (
                  <CheckCircle className="w-3 h-3 mr-1" />
                )}
                {complaint.status === "rejected" && (
                  <XCircle className="w-3 h-3 mr-1" />
                )}
                {complaint.status.replace("_", " ").toUpperCase()}
              </Badge>
            </div>
          </div>
          <div>
            <Label className="text-sm font-medium text-gray-700">
              Priority
            </Label>
            <div className="mt-1">
              <Badge
                variant={
                  complaint.priority === "high" ||
                  complaint.priority === "urgent"
                    ? "destructive"
                    : "secondary"
                }
              >
                {complaint.priority === "low" && "🟢"}
                {complaint.priority === "medium" && "🟡"}
                {complaint.priority === "high" && "🟠"}
                {complaint.priority === "urgent" && "🔴"}
                <span className="ml-1 capitalize">{complaint.priority}</span>
              </Badge>
            </div>
          </div>
        </div>

        {/* Basic Information */}
        <div className="space-y-4">
          <div>
            <Label className="text-sm font-medium text-gray-700">Title</Label>
            <p className="text-sm mt-1">{complaint.title}</p>
          </div>

          <div>
            <Label className="text-sm font-medium text-gray-700">
              Description
            </Label>
            <p className="text-sm mt-1 bg-gray-50 p-3 rounded">
              {complaint.description}
            </p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label className="text-sm font-medium text-gray-700">
                Category
              </Label>
              <p className="text-sm mt-1">{complaint.category}</p>
            </div>
            <div>
              <Label className="text-sm font-medium text-gray-700">
                Complaint Number
              </Label>
              <p className="text-sm mt-1 font-mono">
                {complaint.complaint_number}
              </p>
            </div>
          </div>
        </div>

        {/* Location Information */}
        <div className="space-y-3">
          <h4 className="font-medium flex items-center gap-2">
            <MapPin className="w-4 h-4" />
            Location Information
          </h4>
          <div className="grid gap-3">
            <div>
              <Label className="text-sm font-medium text-gray-700">
                Address
              </Label>
              <p className="text-sm mt-1">{complaint.location}</p>
            </div>
            {complaint.landmark && (
              <div>
                <Label className="text-sm font-medium text-gray-700">
                  Nearby Landmark
                </Label>
                <p className="text-sm mt-1">{complaint.landmark}</p>
              </div>
            )}
          </div>
        </div>

        {/* Timeline */}
        <div className="space-y-3">
          <h4 className="font-medium flex items-center gap-2">
            <History className="w-4 h-4" />
            Timeline
          </h4>
          <div className="space-y-3">
            <div className="flex items-center gap-3 text-sm">
              <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
              <div>
                <p className="font-medium">Complaint Registered</p>
                <p className="text-gray-500">
                  {new Date(complaint.created_at).toLocaleString()}
                </p>
              </div>
            </div>
            {complaint.updated_at !== complaint.created_at && (
              <div className="flex items-center gap-3 text-sm">
                <div className="w-2 h-2 bg-orange-500 rounded-full"></div>
                <div>
                  <p className="font-medium">Last Updated</p>
                  <p className="text-gray-500">
                    {new Date(complaint.updated_at).toLocaleString()}
                  </p>
                </div>
              </div>
            )}
            {complaint.resolved_at && (
              <div className="flex items-center gap-3 text-sm">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <div>
                  <p className="font-medium">Resolved</p>
                  <p className="text-gray-500">
                    {new Date(complaint.resolved_at).toLocaleString()}
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Admin Notes */}
        {complaint.admin_notes && (
          <div className="space-y-3">
            <h4 className="font-medium flex items-center gap-2">
              <User className="w-4 h-4" />
              Admin Notes
            </h4>
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <p className="text-sm text-blue-800">{complaint.admin_notes}</p>
            </div>
          </div>
        )}
      </div>
    </DialogContent>
  );
};

export default TrackComplaint;
