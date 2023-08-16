pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

contract Book{
    struct OptBook{
        uint[] publishedBooks;//已经发表的图书
        uint[] borrowedBooks;//已经借的图书
        uint[] returnedBooks;//还的书
        uint[] commentedBooks;//评论的书
    }

    struct Book{
        address owner;//书籍发布者
        string nameWriter;//书籍名字&作者
        string style;//书籍类型
        string publisherPublishAge;//出版社&出版时间
        string ISBN;//书号
        string intro;//书籍简介
        string cover;//图书封面

        string status;//图书状态(0：在架；1：借阅)
        uint pages;//页数
        uint publishDate;//图书上架时间
        uint score;//图书评分
        uint comment;//图书评论个数
        mapping(uint => Comment) comments;//评价列表
        mapping(uint => BorrowNums) borrowNums;
    }

    struct Comment {
        address reader; // 借阅者
        uint date;      // 评价日期
        uint score;     // 评分
        string content; // 评论正文
    }

    struct BorrowNums{
        uint borrowNum;//借阅次数
    }

    Book[] books;
    uint tempNum = 1;
    mapping(address => OptBook) BooksPool;
    //发布图书成功
    event publishBookSuccess(uint id, string nameWriter, string style, string publisherPublishAge,
        string ISBN,string intro, string cover, uint pages, string status,
        uint publishDate);
    //图书评价成功
    event evaluateSuccess(uint id,address addr,uint score);
    //借书成功
    event borrowSuccess(uint id, address addr);
    //还书成功
    event returnBookSuccess(uint id, address addr);

    //获取已经被借阅的书单
    function getBorrowedBooks() public view returns (uint[] memory){
        return BooksPool[msg.sender].borrowedBooks;
    }
    //获取已经被评论过的书
    function getCommentedBook() public view returns(uint[] memory){
        return BooksPool[msg.sender].commentedBooks;
    }
    //获取发布的书籍
    function getPublishedBooks() public view returns(uint[] memory){
        return BooksPool[msg.sender].publishedBooks;
    }
    //获取还的书
    function getReturnedBooks() public view returns(uint[] memory){
        return BooksPool[msg.sender].returnedBooks;
    }

    //获取书籍数量
    function getBooksLength() public view returns(uint){
        return books.length;
    }

    //获取评价数量
    function getCommentLength(uint id) public view returns (uint) {
        return books[id].comment;
    }

    //获取借阅数据
    function getBorrowNums(uint id) public view returns(uint){
        Book storage book = books[id];
        BorrowNums storage b = book.borrowNums[0];
        return b.borrowNum;
    }

    //获取书籍信息
    function getBookInfo(uint id) public view returns(address, string memory, string memory, string memory,string memory,string memory,string memory,
        string memory, uint, uint, uint, uint){
        require(id < books.length);
        //获取图书,载入合约
        Book storage book = books[id];
        return (book.owner,book.nameWriter,book.style,book.publisherPublishAge,book.ISBN,book.intro,book.cover,book.status,
        book.pages,book.publishDate,book.score,book.comment);
    }

    //获得评价消息
    function getCommentInfo(uint bookId,uint commentId) public view returns(
        address, uint, uint, string memory){
        require(bookId < books.length);
        require(commentId < books[bookId].comment);
        Comment storage c = books[bookId].comments[commentId];
        return (c.reader, c.date, c.score, c.content);
    }

    // 是否已经评价 通过遍历实现
    function isEvaluated(uint id) public view returns (bool) {
        Book storage book = books[id];
        for(uint i = 0; i < book.comment; i++)
            if(book.comments[i].reader == msg.sender)
                return true; // 已经评价
        return false; // 尚未评价
    }

    // 是否已经借阅 通过遍历实现
    function isBorrowed(uint id) public view returns (bool) {
        OptBook storage optBook = BooksPool[msg.sender];
        for(uint i = 0; i < optBook.borrowedBooks.length; i++)
            if(optBook.borrowedBooks[i] == id)
                return true; // 已经借阅
        return false; // 尚未借阅
    }

    function isMyBook(uint id) public view returns(bool){
        Book storage book = books[id];
        if(book.owner == msg.sender)
            return (true);
        return (false);
    }

    //查看图书是否已经离馆
    function isBookLeft(uint id) public payable returns(bool){
        require(id < books.length);
        Book storage book = books[id];
        if(hashCompareInternal(book.status,"离馆"))
            return true;//离馆
        return false;//没有离馆
    }

    //发布图书
    function publishBookInfo(string memory nameWriter, string memory style, string memory publisherPublishAge,string memory ISBN,string memory intro,
        string memory cover,string memory status ,uint pages) public {
        uint id = books.length;
        Book memory book = Book(msg.sender,nameWriter,style,publisherPublishAge,ISBN,intro,cover,status,pages,now,0,0);
        books.push(book);
        BooksPool[msg.sender].publishedBooks.push(id);
        emit publishBookSuccess(id,book.nameWriter,book.style,book.publisherPublishAge,book.ISBN,book.intro,book.cover,
            book.pages,book.status,book.publishDate);
    }

    //评价图书
    function evaluate(uint id, uint score, string memory content) public{
        require(id < books.length);
        // 读取合约
        Book storage book = books[id];
        //require(book.owner != msg.sender && !isEvaluated(id)); // 限制条件
        require(0 <= score && score <= 10); // 合法条件
        // 记录评价
        book.score += score;
        book.comments[book.comment++] = Comment(msg.sender, now, score, content);
        BooksPool[msg.sender].commentedBooks.push(id);
        emit evaluateSuccess(id, msg.sender, book.score);
    }

    //还书
    function returnBook(uint id) public{
        require(id < books.length);
        Book storage book = books[id];
        require(book.owner != msg.sender && isBorrowed(id)); // 限制条件
        book.status = "在架";
        BooksPool[msg.sender].returnedBooks.push(id);
        emit returnBookSuccess(id, msg.sender);
    }

    //借书
    function borrowedBook(uint id) public{
        require(id < books.length);
        Book storage book = books[id];
        require(book.owner != msg.sender && !isBorrowed(id)); // 限制条件
        book.borrowNums[0] = BorrowNums(tempNum++);
        BooksPool[msg.sender].borrowedBooks.push(id);
        book.status="离馆";
        emit borrowSuccess(id, msg.sender);

    }

    //字符串比较
    function hashCompareInternal(string memory a, string memory b) internal returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function () external {
        revert();
    }
}