"use client";

import { useState, useEffect } from "react";
import axios from "axios";

const PeopleIssue = () => {
  const [issueName, setIssueName] = useState("");
  const [description, setDescription] = useState("");
  const [location, setLocation] = useState("");
  const [issueImg, setIssueImg] = useState(null);
  const [loading, setLoading] = useState(false);
  const [publicId, setPublicId] = useState(null);
  const [dateOfComplaint, setDateOfComplaint] = useState(
    new Date().toISOString().split("T")[0]
  );

  // Fetch public ID from localStorage
  useEffect(() => {
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("public-token");
      if (token) {
        axios
          .get("/api/public-sec/profile", {
            headers: { Authorization: `Bearer ${token}` },
          })
          .then((res) => setPublicId(res.data._id))
          .catch(() => localStorage.removeItem("public-token"));
      }
    }
  }, []);

  // Capture image
  const handleCaptureImage = (event) => {
    setIssueImg(event.target.files[0]);
  };

  // Submit issue
  const handleSubmit = async () => {
    setLoading(true);
    try {
      const formData = new FormData();
      formData.append("userId", publicId);
      formData.append("issue_type", issueName);
      formData.append("description", description);
      formData.append("location", location);
      formData.append("approval", 0);
      formData.append("denial", 0);
      formData.append("status", "Pending");
      formData.append("date_of_complaint", dateOfComplaint);

      if (issueImg) {
        formData.append("image", issueImg);
      }

      await axios.post("/api/public-issue", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
    } catch (error) {
      console.error("Error sending request:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col items-center p-6 bg-black min-h-screen text-white">
      <h2 className="text-3xl font-semibold mb-6 text-center text-teal-400">
        Raise an Issue
      </h2>

      <input
        type="text"
        placeholder="Issue Name"
        value={issueName}
        onChange={(e) => setIssueName(e.target.value)}
        className="w-full p-2 border border-gray-600 bg-gray-800 rounded mt-2 text-white placeholder-gray-400"
      />

      <textarea
        placeholder="Description"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        className="w-full p-2 border border-gray-600 bg-gray-800 rounded mt-2 text-white placeholder-gray-400"
      ></textarea>

      <input
        type="text"
        placeholder="Enter Location"
        value={location}
        onChange={(e) => setLocation(e.target.value)}
        className="w-full p-2 border border-gray-600 bg-gray-800 rounded mt-2 text-white placeholder-gray-400"
      />

      <input
        type="file"
        accept="image/*"
        onChange={handleCaptureImage}
        className="mt-2 bg-gray-800 p-2 rounded cursor-pointer text-white"
      />

      <button
        onClick={handleSubmit}
        className={`mt-6 px-4 py-2 rounded-lg transition font-semibold ${
          loading
            ? "bg-gray-500 cursor-not-allowed"
            : "bg-teal-500 hover:bg-teal-400"
        }`}
        disabled={loading}
      >
        {loading ? "Submitting..." : "Submit Issue"}
      </button>
    </div>
  );
};

export default PeopleIssue;
