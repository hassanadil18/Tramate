// This is the main application JavaScript file

document.addEventListener('DOMContentLoaded', function() {
  // Mobile menu toggle
  const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
  const mainNav = document.querySelector('.main-nav');
  
  if (mobileMenuToggle) {
    mobileMenuToggle.addEventListener('click', function() {
      this.classList.toggle('active');
      mainNav.classList.toggle('active');
      document.body.classList.toggle('menu-open');
    });
  }
  
  // Close the mobile menu when clicking outside
  document.addEventListener('click', function(event) {
    if (mainNav && mainNav.classList.contains('active') && 
        !event.target.closest('.main-nav') && 
        !event.target.closest('.mobile-menu-toggle')) {
      mainNav.classList.remove('active');
      if (mobileMenuToggle) {
        mobileMenuToggle.classList.remove('active');
      }
      document.body.classList.remove('menu-open');
    }
  });
  
  // Scroll to top button
  const scrollToTopButton = document.querySelector('.scroll-to-top');
  
  if (scrollToTopButton) {
    // Show/hide scroll-to-top button based on scroll position
    window.addEventListener('scroll', function() {
      if (window.pageYOffset > 300) {
        scrollToTopButton.classList.add('visible');
      } else {
        scrollToTopButton.classList.remove('visible');
      }
    });
    
    // Smooth scroll to top when button is clicked
    scrollToTopButton.addEventListener('click', function() {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
  }
  
  // Flash messages
  const closeFlashButtons = document.querySelectorAll('.close-flash');
  
  closeFlashButtons.forEach(button => {
    button.addEventListener('click', function() {
      const flashMessage = this.closest('.flash-message');
      if (flashMessage) {
        flashMessage.style.opacity = '0';
        setTimeout(() => {
          flashMessage.style.display = 'none';
        }, 500);
      }
    });
  });
  
  // Auto-hide flash messages after 5 seconds
  const flashMessages = document.querySelectorAll('.flash-message');
  flashMessages.forEach(message => {
    setTimeout(() => {
      message.style.opacity = '0';
      setTimeout(() => {
        message.style.display = 'none';
      }, 500);
    }, 5000);
  });
  
  // Interactive elements
  const animateOnScroll = function() {
    const elements = document.querySelectorAll('.feature-card, .step, .channel-card, .pricing-card, .testimonial');
    
    elements.forEach(element => {
      const elementPosition = element.getBoundingClientRect().top;
      const screenPosition = window.innerHeight / 1.2;
      
      if (elementPosition < screenPosition) {
        element.classList.add('animate');
      }
    });
  };
  
  // Add animate class on scroll
  window.addEventListener('scroll', animateOnScroll);
  // Initial check on page load
  animateOnScroll();
  
  // FAQ accordion functionality
  const faqQuestions = document.querySelectorAll('.faq-question');
  
  faqQuestions.forEach(question => {
    question.addEventListener('click', function() {
      const faqItem = this.closest('.faq-item');
      const answer = faqItem.querySelector('.faq-answer');
      
      // Toggle the active class
      faqItem.classList.toggle('active');
      
      // Animate the answer
      if (faqItem.classList.contains('active')) {
        answer.style.maxHeight = answer.scrollHeight + 'px';
      } else {
        answer.style.maxHeight = '0';
      }
    });
  });
});
