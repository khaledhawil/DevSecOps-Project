package handlers

import (
	"math"
	"net/http"
	"strconv"

	"github.com/devsecops/user-service/internal/models"
	"github.com/devsecops/user-service/internal/repository"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// UserHandler handles user-related HTTP requests
type UserHandler struct {
	repo *repository.UserRepository
	log  *logrus.Logger
}

// NewUserHandler creates a new user handler
func NewUserHandler(repo *repository.UserRepository, log *logrus.Logger) *UserHandler {
	return &UserHandler{
		repo: repo,
		log:  log,
	}
}

// CreateUser creates a new user
func (h *UserHandler) CreateUser(c *gin.Context) {
	var req models.CreateUserRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "VALIDATION_ERROR",
				Message: "Invalid request data",
				Details: []string{err.Error()},
			},
		})
		return
	}

	// Check if email already exists
	if h.repo.ExistsByEmail(req.Email) {
		c.JSON(http.StatusConflict, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "EMAIL_EXISTS",
				Message: "Email already registered",
			},
		})
		return
	}

	// Check if username already exists
	if h.repo.ExistsByUsername(req.Username) {
		c.JSON(http.StatusConflict, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "USERNAME_EXISTS",
				Message: "Username already taken",
			},
		})
		return
	}

	// Create user
	user := &models.User{
		Email:     req.Email,
		Username:  req.Username,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Phone:     req.Phone,
		IsActive:  true,
	}

	if err := h.repo.Create(user, req.Password); err != nil {
		h.log.Errorf("Failed to create user: %v", err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to create user",
			},
		})
		return
	}

	h.log.Infof("User created: %s", user.ID)
	c.JSON(http.StatusCreated, models.SuccessResponse{
		Success: true,
		Data:    user.ToResponse(),
		Message: "User created successfully",
	})
}

// GetUser retrieves a user by ID
func (h *UserHandler) GetUser(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INVALID_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	user, err := h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "USER_NOT_FOUND",
				Message: "User not found",
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Data:    user.ToResponse(),
	})
}

// ListUsers retrieves all users with pagination
func (h *UserHandler) ListUsers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	users, total, err := h.repo.List(page, limit)
	if err != nil {
		h.log.Errorf("Failed to list users: %v", err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve users",
			},
		})
		return
	}

	// Convert to response format
	userResponses := make([]*models.UserResponse, len(users))
	for i, user := range users {
		userResponses[i] = user.ToResponse()
	}

	totalPages := int(math.Ceil(float64(total) / float64(limit)))

	c.JSON(http.StatusOK, models.PaginatedResponse{
		Success: true,
		Data:    userResponses,
		Pagination: models.PaginationMeta{
			Page:       page,
			Limit:      limit,
			Total:      total,
			TotalPages: totalPages,
		},
	})
}

// UpdateUser updates a user
func (h *UserHandler) UpdateUser(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INVALID_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	var req models.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "VALIDATION_ERROR",
				Message: "Invalid request data",
				Details: []string{err.Error()},
			},
		})
		return
	}

	// Check if user exists
	user, err := h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "USER_NOT_FOUND",
				Message: "User not found",
			},
		})
		return
	}

	// Build updates map
	updates := make(map[string]interface{})
	if req.FirstName != "" {
		updates["first_name"] = req.FirstName
	}
	if req.LastName != "" {
		updates["last_name"] = req.LastName
	}
	if req.Phone != "" {
		updates["phone"] = req.Phone
	}
	if req.AvatarURL != "" {
		updates["avatar_url"] = req.AvatarURL
	}

	if err := h.repo.Update(id, updates); err != nil {
		h.log.Errorf("Failed to update user: %v", err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to update user",
			},
		})
		return
	}

	// Fetch updated user
	user, _ = h.repo.FindByID(id)

	h.log.Infof("User updated: %s", id)
	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Data:    user.ToResponse(),
		Message: "User updated successfully",
	})
}

// DeleteUser soft deletes a user
func (h *UserHandler) DeleteUser(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INVALID_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	// Check if user exists
	_, err = h.repo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "USER_NOT_FOUND",
				Message: "User not found",
			},
		})
		return
	}

	if err := h.repo.Delete(id); err != nil {
		h.log.Errorf("Failed to delete user: %v", err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to delete user",
			},
		})
		return
	}

	h.log.Infof("User deleted: %s", id)
	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "User deleted successfully",
	})
}

// GetProfile retrieves user profile
func (h *UserHandler) GetProfile(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INVALID_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	profile, err := h.repo.GetProfile(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "PROFILE_NOT_FOUND",
				Message: "Profile not found",
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Data:    profile,
	})
}

// UpdateProfile updates user profile
func (h *UserHandler) UpdateProfile(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INVALID_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "VALIDATION_ERROR",
				Message: "Invalid request data",
				Details: []string{err.Error()},
			},
		})
		return
	}

	// Build updates map
	updates := make(map[string]interface{})
	if req.Bio != "" {
		updates["bio"] = req.Bio
	}
	if req.DateOfBirth != nil {
		updates["date_of_birth"] = req.DateOfBirth
	}
	if req.Country != "" {
		updates["country"] = req.Country
	}
	if req.City != "" {
		updates["city"] = req.City
	}
	if req.Timezone != "" {
		updates["timezone"] = req.Timezone
	}
	if req.Language != "" {
		updates["language"] = req.Language
	}
	if req.Preferences != "" {
		updates["preferences"] = req.Preferences
	}

	if err := h.repo.UpdateProfile(id, updates); err != nil {
		h.log.Errorf("Failed to update profile: %v", err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to update profile",
			},
		})
		return
	}

	// Fetch updated profile
	profile, _ := h.repo.GetProfile(id)

	h.log.Infof("Profile updated: %s", id)
	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Data:    profile,
		Message: "Profile updated successfully",
	})
}
