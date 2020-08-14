/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name
FROM Facilities
WHERE membercost >0



/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT( name )
FROM Facilities
WHERE membercost =0




/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost >0
AND membercost < ( 20 * monthlymaintenance /100 )




/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid
IN ( 1, 5 )



/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name,monthlymaintenance,
CASE WHEN monthlymaintenance >100
THEN 'expensive'
ELSE 'cheap'
END AS monthlymaintenance
FROM Facilities




/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate = (
SELECT MAX( joindate )
FROM Members )



/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT (
CONCAT( m.firstname, " ", m.surname)
) AS member_Name,f.name AS Name_of_Court
FROM Facilities f
INNER JOIN Bookings b ON f.facid = b.facid
INNER JOIN Members m ON b.memid = m.memid
WHERE f.name LIKE "Tennis%"
ORDER BY m.firstname


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

(select f.name ,f.membercost * b.slots AS cost,CONCAT(m.firstname," ",m.surname) AS member_name,b.* from Bookings b
INNER JOIN Facilities f
ON b.facid = f.facid
INNER JOIN Members m
ON b.memid = m.memid
where b.starttime like "2012-09-14%" AND (f.membercost * b.slots > 30 AND m.memid > 0))

UNION

(select f.name,f.guestcost * b.slots AS cost,CONCAT(m.firstname," ",m.surname) AS member_name,b.* from Bookings b
INNER JOIN Facilities f
ON b.facid = f.facid
INNER JOIN Members m
ON b.memid = m.memid
where b.starttime like "2012-09-14%" AND (f.guestcost * b.slots > 30 AND m.memid = 0))
ORDER BY cost DESC



/* Q9: This time, produce the same result as in Q8, but using a subquery. */


select r.facility_name,r.member_name,r.bookid,r.memid,r.facid,r.slots,r.starttime,
       (case when r.memid = 0 THEN r.guestcost * r.slots
       else r.membercost * r.slots END) as cost 
FROM (select f.name as facility_name,f.membercost,f.guestcost,CONCAT(m.firstname," ",m.surname) AS member_name,b.*  from Bookings b
INNER JOIN Facilities f
ON b.facid = f.facid
INNER JOIN Members m
ON b.memid = m.memid
where b.starttime like "2012-09-14%" AND ((f.membercost*b.slots > 30 AND m.memid > 0) OR (f.guestcost*b.slots > 30 AND m.memid = 0))
) AS r
ORDER BY cost DESC



/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT *
FROM (

SELECT f.facid, f.name, f.membercost, f.guestcost, b.slots, SUM(
CASE WHEN b.memid >0
THEN f.membercost * b.slots
ELSE f.guestcost * b.slots
END ) AS revenue
FROM Facilities f
LEFT JOIN Bookings b ON f.facid = b.facid
GROUP BY facid
) AS final
WHERE final.revenue <1000
ORDER BY final.revenue



/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

select m.memid,m.surname,m.firstname,m.recommendedby,concat(m1.surname," ",m1.firstname) as recommendedby_name from Members m
LEFT JOIN (
           select memid,surname,firstname from Members
           where recommendedby in (select memid from Members) and recommendedby >= 0) m1
ON m.recommendedby = m1.memid
where m.recommendedby > 0
order by recommendedby_name

  


/* Q12: Find the facilities with their usage by member, but not guests */

SELECT f.name , sum(b.slots) AS member_usage, b.memid
FROM Facilities f
INNER JOIN Bookings b
WHERE f.facid = b.facid AND b.memid > 0
GROUP BY b.memid




/* Q13: Find the facilities usage by month, but not guests */

select b.facid,EXTRACT(MONTH FROM b.starttime) as month,f.name,sum(b.slots) AS member_usage,b.memid from Bookings b
INNER JOIN Facilities f
ON b.facid = f.facid
where b.memid > 0
group by month,b.facid
order by month

