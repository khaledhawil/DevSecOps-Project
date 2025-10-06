package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User represents a user in the system
type User struct {
	ID           uuid.UUID      `gorm:"type:uuid;primary_key;default:uuid_generate_v4()" json:"id"`
	Email        string         `gorm:"type:varchar(255);uniqueIndex;not null" json:"email" binding:"required,email"`
	Username     string         `gorm:"type:varchar(100);uniqueIndex;not null" json:"username" binding:"required,min=3,max=100"`
	PasswordHash string         `gorm:"type:varchar(255);not null" json:"-"`
	FirstName    string         `gorm:"type:varchar(100)" json:"first_name" binding:"required"`
	LastName     string         `gorm:"type:varchar(100)" json:"last_name" binding:"required"`
	Phone        string         `gorm:"type:varchar(20)" json:"phone"`
	AvatarURL    string         `gorm:"type:text" json:"avatar_url"`
	IsActive     bool           `gorm:"default:true" json:"is_active"`
	IsVerified   bool           `gorm:"default:false" json:"is_verified"`
	Role         string         `gorm:"type:varchar(50);default:'user'" json:"role"`
	LastLoginAt  *time.Time     `json:"last_login_at"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// UserProfile represents additional user profile information
type UserProfile struct {
	ID          uuid.UUID  `gorm:"type:uuid;primary_key;default:uuid_generate_v4()" json:"id"`
	UserID      uuid.UUID  `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	Bio         string     `gorm:"type:text" json:"bio"`
	DateOfBirth *time.Time `json:"date_of_birth"`
	Country     string     `gorm:"type:varchar(100)" json:"country"`
	City        string     `gorm:"type:varchar(100)" json:"city"`
	Timezone    string     `gorm:"type:varchar(50)" json:"timezone"`
	Language    string     `gorm:"type:varchar(10);default:'en'" json:"language"`
	Preferences string     `gorm:"type:jsonb;default:'{}'" json:"preferences"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
	User        User       `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"-"`
}

// CreateUserRequest represents the request body for creating a user
type CreateUserRequest struct {
	Email     string `json:"email" binding:"required,email"`
	Username  string `json:"username" binding:"required,min=3,max=100"`
	Password  string `json:"password" binding:"required,min=8"`
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name" binding:"required"`
	Phone     string `json:"phone"`
}

// UpdateUserRequest represents the request body for updating a user
type UpdateUserRequest struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Phone     string `json:"phone"`
	AvatarURL string `json:"avatar_url"`
}

// UpdateProfileRequest represents the request body for updating a user profile
type UpdateProfileRequest struct {
	Bio         string     `json:"bio"`
	DateOfBirth *time.Time `json:"date_of_birth"`
	Country     string     `json:"country"`
	City        string     `json:"city"`
	Timezone    string     `json:"timezone"`
	Language    string     `json:"language"`
	Preferences string     `json:"preferences"`
}

// UserResponse represents the response for user operations
type UserResponse struct {
	ID          uuid.UUID  `json:"id"`
	Email       string     `json:"email"`
	Username    string     `json:"username"`
	FirstName   string     `json:"first_name"`
	LastName    string     `json:"last_name"`
	Phone       string     `json:"phone"`
	AvatarURL   string     `json:"avatar_url"`
	IsActive    bool       `json:"is_active"`
	IsVerified  bool       `json:"is_verified"`
	Role        string     `json:"role"`
	LastLoginAt *time.Time `json:"last_login_at"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

// TableName overrides the table name for User model
func (User) TableName() string {
	return "users"
}

// TableName overrides the table name for UserProfile model
func (UserProfile) TableName() string {
	return "user_profiles"
}

// ToResponse converts User model to UserResponse
func (u *User) ToResponse() *UserResponse {
	return &UserResponse{
		ID:          u.ID,
		Email:       u.Email,
		Username:    u.Username,
		FirstName:   u.FirstName,
		LastName:    u.LastName,
		Phone:       u.Phone,
		AvatarURL:   u.AvatarURL,
		IsActive:    u.IsActive,
		IsVerified:  u.IsVerified,
		Role:        u.Role,
		LastLoginAt: u.LastLoginAt,
		CreatedAt:   u.CreatedAt,
		UpdatedAt:   u.UpdatedAt,
	}
}
