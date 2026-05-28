public class Main {
    public static void main(String[] args) {
        System.out.println("Starting Library Management System...");

        // Initialize the repository
        BookRepository repository = new BookRepository();



        // Assuming our dummy data from Step 1 has User ID 1 and Book ID 1
        int userId = 1;
        int bookId = 1;

        System.out.println("Attempting to borrow book ID " + bookId + " for user ID " + userId + "...");

        // Execute the borrow method
        boolean success = repository.borrowBook(userId, bookId);

        if (success) {
            System.out.println("Success! Check your MySQL database to see the updated available_copies and the new Transaction record.");
        } else {
            System.out.println("Failed to borrow the book.");
        }
    }
}