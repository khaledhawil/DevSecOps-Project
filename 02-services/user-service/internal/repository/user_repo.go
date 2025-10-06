package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/devsecops/user-service/internal/models"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// UserRepository handles database operations for users
type UserRepository struct {
	db    *gorm.DB
	cache CacheInterface
	log   *logrus.Logger
}

// CacheInterface defines cache operations
type CacheInterface interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error
	Delete(ctx context.Context, key string) error
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *gorm.DB, cache CacheInterface, log *logrus.Logger) *UserRepository {
	return &UserRepository{
		db:    db,
		cache: cache,
		log:   log,
	}
}

// Create creates a new user
func (r *UserRepository) Create(user *models.User, password string) error {
	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		r.log.Errorf("Failed to hash password: %v", err)
		return fmt.Errorf("failed to hash password")
	}

	user.ID = uuid.New()
	user.PasswordHash = string(hashedPassword)
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()

	if err := r.db.Create(user).Error; err != nil {
		r.log.Errorf("Failed to create user: %v", err)
		return err
	}

	// Create default user profile
	profile := &models.UserProfile{
		ID:        uuid.New(),
		UserID:    user.ID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := r.db.Create(profile).Error; err != nil {
		r.log.Warnf("Failed to create user profile: %v", err)
	}

	return nil
}

// FindByID finds a user by ID
func (r *UserRepository) FindByID(id uuid.UUID) (*models.User, error) {
	// Try cache first
	if r.cache != nil {
		cacheKey := fmt.Sprintf("user:%s", id.String())
		cached, err := r.cache.Get(context.Background(), cacheKey)
		if err == nil && cached != "" {
			var user models.User
			if err := json.Unmarshal([]byte(cached), &user); err == nil {
				r.log.Debugf("User %s found in cache", id)
				return &user, nil
			}
		}
	}

	// Query database
	var user models.User
	if err := r.db.Where("id = ?", id).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("user not found")
		}
		r.log.Errorf("Failed to find user: %v", err)
		return nil, err
	}

	// Cache the result
	if r.cache != nil {
		cacheKey := fmt.Sprintf("user:%s", id.String())
		userJSON, _ := json.Marshal(user)
		_ = r.cache.Set(context.Background(), cacheKey, string(userJSON), 5*time.Minute)
	}

	return &user, nil
}

// FindByEmail finds a user by email
func (r *UserRepository) FindByEmail(email string) (*models.User, error) {
	var user models.User
	if err := r.db.Where("email = ?", email).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("user not found")
		}
		r.log.Errorf("Failed to find user by email: %v", err)
		return nil, err
	}

	return &user, nil
}

// FindByUsername finds a user by username
func (r *UserRepository) FindByUsername(username string) (*models.User, error) {
	var user models.User
	if err := r.db.Where("username = ?", username).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("user not found")
		}
		r.log.Errorf("Failed to find user by username: %v", err)
		return nil, err
	}

	return &user, nil
}

// List retrieves users with pagination
func (r *UserRepository) List(page, limit int) ([]models.User, int64, error) {
	var users []models.User
	var total int64

	offset := (page - 1) * limit

	// Count total records
	if err := r.db.Model(&models.User{}).Count(&total).Error; err != nil {
		r.log.Errorf("Failed to count users: %v", err)
		return nil, 0, err
	}

	// Query with pagination
	if err := r.db.Offset(offset).Limit(limit).Find(&users).Error; err != nil {
		r.log.Errorf("Failed to list users: %v", err)
		return nil, 0, err
	}

	return users, total, nil
}

// Update updates a user
func (r *UserRepository) Update(id uuid.UUID, updates map[string]interface{}) error {
	updates["updated_at"] = time.Now()

	if err := r.db.Model(&models.User{}).Where("id = ?", id).Updates(updates).Error; err != nil {
		r.log.Errorf("Failed to update user: %v", err)
		return err
	}

	// Invalidate cache
	if r.cache != nil {
		cacheKey := fmt.Sprintf("user:%s", id.String())
		_ = r.cache.Delete(context.Background(), cacheKey)
	}

	return nil
}

// Delete soft deletes a user
func (r *UserRepository) Delete(id uuid.UUID) error {
	if err := r.db.Delete(&models.User{}, id).Error; err != nil {
		r.log.Errorf("Failed to delete user: %v", err)
		return err
	}

	// Invalidate cache
	if r.cache != nil {
		cacheKey := fmt.Sprintf("user:%s", id.String())
		_ = r.cache.Delete(context.Background(), cacheKey)
	}

	return nil
}

// GetProfile retrieves user profile
func (r *UserRepository) GetProfile(userID uuid.UUID) (*models.UserProfile, error) {
	var profile models.UserProfile
	if err := r.db.Where("user_id = ?", userID).First(&profile).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("profile not found")
		}
		r.log.Errorf("Failed to get profile: %v", err)
		return nil, err
	}

	return &profile, nil
}

// UpdateProfile updates user profile
func (r *UserRepository) UpdateProfile(userID uuid.UUID, updates map[string]interface{}) error {
	updates["updated_at"] = time.Now()

	if err := r.db.Model(&models.UserProfile{}).Where("user_id = ?", userID).Updates(updates).Error; err != nil {
		r.log.Errorf("Failed to update profile: %v", err)
		return err
	}

	return nil
}

// ExistsByEmail checks if user exists by email
func (r *UserRepository) ExistsByEmail(email string) bool {
	var count int64
	r.db.Model(&models.User{}).Where("email = ?", email).Count(&count)
	return count > 0
}

// ExistsByUsername checks if user exists by username
func (r *UserRepository) ExistsByUsername(username string) bool {
	var count int64
	r.db.Model(&models.User{}).Where("username = ?", username).Count(&count)
	return count > 0
}
