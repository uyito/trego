const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error with context
  const errorContext = {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('user-agent'),
    userId: req.user?.uid,
    body: req.body,
    params: req.params,
    query: req.query
  };

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Invalid ID format';
    error = { message, statusCode: 400 };
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const message = 'Duplicate field value entered';
    error = { message, statusCode: 400 };
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(val => val.message).join(', ');
    error = { message, statusCode: 400 };
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    const message = 'Invalid token';
    error = { message, statusCode: 401 };
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token expired';
    error = { message, statusCode: 401 };
  }

  // Firebase auth errors
  if (err.code === 'auth/id-token-expired') {
    const message = 'Authentication token expired';
    error = { message, statusCode: 401 };
  }

  if (err.code === 'auth/id-token-revoked') {
    const message = 'Authentication token revoked';
    error = { message, statusCode: 401 };
  }

  // Rate limit errors
  if (err.status === 429) {
    const message = 'Too many requests, please try again later';
    error = { message, statusCode: 429 };
  }

  // OpenAI API errors
  if (err.response?.status === 429 && err.response?.data?.error?.type === 'rate_limit_exceeded') {
    const message = 'AI service temporarily unavailable due to high demand';
    error = { message, statusCode: 503 };
  }

  if (err.response?.status === 401 && err.config?.url?.includes('openai')) {
    const message = 'AI service configuration error';
    error = { message, statusCode: 500 };
  }

  // Default status code
  const statusCode = error.statusCode || 500;

  // Log based on severity
  if (statusCode >= 500) {
    logger.error('Server Error:', errorContext);
  } else if (statusCode >= 400) {
    logger.warn('Client Error:', errorContext);
  }

  // Response format
  const response = {
    error: error.message || 'Server Error',
    ...(process.env.NODE_ENV === 'development' && {
      stack: err.stack,
      details: errorContext
    })
  };

  // Add specific error codes for client handling
  if (err.name === 'ValidationError') {
    response.type = 'validation_error';
    response.fields = Object.keys(err.errors);
  }

  if (err.code === 11000) {
    response.type = 'duplicate_error';
    const field = Object.keys(err.keyPattern)[0];
    response.field = field;
  }

  if (statusCode === 401) {
    response.type = 'authentication_error';
  }

  if (statusCode === 403) {
    response.type = 'authorization_error';
  }

  if (statusCode === 429) {
    response.type = 'rate_limit_error';
    response.retryAfter = err.retryAfter || 60;
  }

  res.status(statusCode).json(response);
};

module.exports = errorHandler;