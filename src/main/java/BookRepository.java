import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

public class BookRepository {

    /**
     * Handles the borrowing of a book with full ACID compliance.
     * Uses row-level locking (FOR UPDATE) to prevent concurrency anomalies.
     */
    public boolean borrowBook(int userId, int bookId) {
        Connection conn = null;

        // Queries
        String checkAvailabilitySql = "SELECT available_copies FROM Books WHERE id = ? FOR UPDATE";
        String insertTransactionSql = "INSERT INTO Transactions (book_id, user_id, borrow_date, due_date, status) VALUES (?, ?, ?, ?, 'BORROWED')";

        try {
            conn = DatabaseConnection.getInstance().getConnection();

            // 1. Begin Transaction
            conn.setAutoCommit(false);

            // 2. Check Availability with a Write Lock
            try (PreparedStatement checkStmt = conn.prepareStatement(checkAvailabilitySql)) {
                checkStmt.setInt(1, bookId);

                try (ResultSet rs = checkStmt.executeQuery()) {
                    if (rs.next()) {
                        int availableCopies = rs.getInt("available_copies");

                        if (availableCopies <= 0) {
                            System.out.println("Transaction Failed: No copies available.");
                            conn.rollback();
                            return false;
                        }
                    } else {
                        System.out.println("Transaction Failed: Book not found.");
                        conn.rollback();
                        return false;
                    }
                }
            }

            // 3. Insert Transaction
            // (The MySQL Trigger 'trg_after_loan_insert' will automatically decrement the book count)
            try (PreparedStatement insertStmt = conn.prepareStatement(insertTransactionSql)) {
                insertStmt.setInt(1, bookId);
                insertStmt.setInt(2, userId);
                insertStmt.setDate(3, java.sql.Date.valueOf(LocalDate.now()));
                insertStmt.setDate(4, java.sql.Date.valueOf(LocalDate.now().plusDays(14))); // 14-day loan period

                int rowsAffected = insertStmt.executeUpdate();
                if (rowsAffected == 0) {
                    throw new SQLException("Inserting transaction failed, no rows affected.");
                }
            }

            // 4. Commit Transaction
            conn.commit();
            System.out.println("Book borrowed successfully!");
            return true;

        } catch (SQLException e) {
            // 5. Rollback on any failure
            if (conn != null) {
                try {
                    System.err.println("Transaction is being rolled back due to an error.");
                    conn.rollback();
                } catch (SQLException excep) {
                    excep.printStackTrace();
                }
            }
            e.printStackTrace();
            return false;

        } finally {
            // 6. Restore default auto-commit state
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}