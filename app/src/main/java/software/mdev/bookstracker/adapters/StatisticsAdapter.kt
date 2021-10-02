package software.mdev.bookstracker.adapters

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelProviders
import androidx.recyclerview.widget.AsyncListDiffer
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.BarData
import com.github.mikephil.charting.data.BarDataSet
import com.github.mikephil.charting.data.BarEntry
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.formatter.DefaultValueFormatter
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter
import com.github.mikephil.charting.formatter.ValueFormatter
import com.github.mikephil.charting.utils.ColorTemplate
import kotlinx.android.synthetic.main.item_statistics.view.*
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import software.mdev.bookstracker.R
import software.mdev.bookstracker.data.db.BooksDatabase
import software.mdev.bookstracker.data.db.LanguageDatabase
import software.mdev.bookstracker.data.db.YearDatabase
import software.mdev.bookstracker.data.db.entities.Year
import software.mdev.bookstracker.data.repositories.BooksRepository
import software.mdev.bookstracker.data.repositories.LanguageRepository
import software.mdev.bookstracker.data.repositories.OpenLibraryRepository
import software.mdev.bookstracker.data.repositories.YearRepository
import software.mdev.bookstracker.ui.bookslist.dialogs.ChallengeDialog
import software.mdev.bookstracker.ui.bookslist.dialogs.ChallengeDialogListener
import software.mdev.bookstracker.ui.bookslist.fragments.StatisticsFragment
import software.mdev.bookstracker.ui.bookslist.viewmodel.BooksViewModel
import software.mdev.bookstracker.ui.bookslist.viewmodel.BooksViewModelProviderFactory
import java.math.RoundingMode
import java.text.DecimalFormat
import java.util.*
import java.util.concurrent.TimeUnit
import com.github.mikephil.charting.utils.ViewPortHandler


class StatisticsAdapter(
    private val statisticsFragment: StatisticsFragment,
    private val listOfYearsFromDb: List<Year>
) : RecyclerView.Adapter<StatisticsAdapter.StatisticsViewHolder>() {

    private var monthsList = ArrayList<String>()

    inner class StatisticsViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView)

    lateinit var viewModel: BooksViewModel

    private val differCallback = object : DiffUtil.ItemCallback<Year>() {
        override fun areItemsTheSame(oldItem: Year, newItem: Year): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: Year, newItem: Year): Boolean {
            return oldItem == newItem
        }
    }

    val differ = AsyncListDiffer(this, differCallback)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): StatisticsViewHolder {
        val view =
            LayoutInflater.from(parent.context).inflate(R.layout.item_statistics, parent, false)

        val database = BooksDatabase(view.context)
        val yearDatabase = YearDatabase(view.context)
        val languageDatabase = LanguageDatabase(view.context)

        val booksRepository = BooksRepository(database)
        val yearRepository = YearRepository(yearDatabase)
        val openLibraryRepository = OpenLibraryRepository()
        val languageRepository = LanguageRepository(languageDatabase)

        val booksViewModelProviderFactory = BooksViewModelProviderFactory(
            booksRepository,
            yearRepository,
            openLibraryRepository,
            languageRepository
        )

        viewModel = ViewModelProvider(statisticsFragment, booksViewModelProviderFactory).get(
            BooksViewModel::class.java
        )

        val viewModel =
            ViewModelProviders.of(statisticsFragment, booksViewModelProviderFactory).get(BooksViewModel::class.java)

        return StatisticsViewHolder(view)
    }

    override fun getItemCount(): Int {
        return differ.currentList.size
    }

    override fun onBindViewHolder(holder: StatisticsViewHolder, position: Int) {
        val curYear = differ.currentList[position]
        val df = DecimalFormat("#.#")
        df.roundingMode = RoundingMode.CEILING

        val foundYear: Year?
        if (position == 0) {
            val tvChallengeTitleText = holder.itemView.resources.getString(R.string.tvChallengeTitle) + " " + Calendar.getInstance().get(Calendar.YEAR).toString()
            holder.itemView.tvChallengeTitle.text = tvChallengeTitleText

            foundYear = listOfYearsFromDb.find {
                it.year == Calendar.getInstance().get(Calendar.YEAR).toString()
            }
        } else {
            val tvChallengeTitleText = holder.itemView.resources.getString(R.string.tvChallengeTitle) + " " + curYear.year
            holder.itemView.tvChallengeTitle.text = tvChallengeTitleText

            foundYear = listOfYearsFromDb.find { it.year == curYear.year }
        }

        if (position == 0 && curYear.yearBooks == 0) {
            holder.itemView.apply {
                tvLooksEmptyStatistics.visibility = View.VISIBLE

                clBooksRead.visibility = View.GONE
                clPagesRead.visibility = View.GONE
                clAvgRating.visibility = View.GONE
                clChallenge.visibility = View.GONE
                clQuickestRead.visibility = View.GONE
                clMonths.visibility = View.GONE
                clAvgReadingTime.visibility = View.GONE
                clAvgPages.visibility = View.GONE
                clLongestBook.visibility = View.GONE
                clShortestBook.visibility = View.GONE
            }
        } else {
            holder.itemView.tvLooksEmptyStatistics.visibility = View.GONE
        }

        var challengeBooksRead = "0"

        holder.itemView.apply {

            setCardsAnimation(this)

            tvBooksReadValue.text = curYear.yearBooks.toString()

            tvPagesReadValue.text = curYear.yearPages.toString()

            tvAvgRatingValue.text = curYear.avgRating.toBigDecimal().setScale(1, RoundingMode.UP).toDouble().toString()

            if (curYear.yearQuickestBook == "null"){
                tvQuickestReadBook.text = holder.itemView.resources.getString(R.string.need_more_data)
                tvQuickestReadValue.visibility = View.GONE
            } else {
                var string = convertLongToDays(curYear.yearQuickestBookVal.toLong()) + " " + holder.itemView.resources.getString(R.string.days)
                tvQuickestReadBook.text = curYear.yearQuickestBook
                tvQuickestReadValue.text = string
            }

            if (curYear.yearLongestBook == "null"){
                tvLongestBook.text = holder.itemView.resources.getString(R.string.need_more_data)
                tvLongestBookValue.visibility = View.GONE
            } else {
                var string = curYear.yearLongestBookVal.toString() + " " + holder.itemView.resources.getString(R.string.pages)
                tvLongestBookValue.text = string
                tvLongestBook.text = curYear.yearLongestBook
            }

            if (curYear.yearShortestBook == "null"){
                tvShortestBook.text = holder.itemView.resources.getString(R.string.need_more_data)
                tvShortestBookValue.visibility = View.GONE
            } else {
                var string = curYear.yearShortestBookVal.toString() + " " + holder.itemView.resources.getString(R.string.pages)
                tvShortestBookValue.text = string
                tvShortestBook.text = curYear.yearShortestBook
            }

            if (curYear.yearAvgReadingTime == "0" || curYear.yearAvgReadingTime == "null"){
                tvAvgReadingTimeValue.text = holder.itemView.resources.getString(R.string.need_more_data)
            } else {
                var string = convertLongToDays(curYear.yearAvgReadingTime.toLong()) + " " + holder.itemView.resources.getString(R.string.days)
                tvAvgReadingTimeValue.text = string
            }

            if (curYear.yearAvgPages == 0){
                tvAvgPagesValue.text = holder.itemView.resources.getString(R.string.need_more_data)
            } else {
                tvAvgPagesValue.text = curYear.yearAvgPages.toString()
            }



            if (position == 0 && itemCount > 1) {
                if (differ.currentList[1].year == Calendar.getInstance().get(Calendar.YEAR)
                        .toString()
                ) {
                    challengeBooksRead = differ.currentList[1].yearBooks.toString()
                }
            } else {
                challengeBooksRead = curYear.yearBooks.toString()
            }

            var challengeBooksTarget = "null"
            if (foundYear?.yearChallengeBooks != null) {
                challengeBooksTarget = foundYear?.yearChallengeBooks.toString()
            }

            val tvChallengeText = "$challengeBooksRead / $challengeBooksTarget"
            tvChallengeValue.text = tvChallengeText

            var target = challengeBooksTarget
            var read = challengeBooksRead

            if (target != "null" && read != "null") {
                var challengePercent = ((read.toFloat()/target.toFloat())*100).toInt()
                pbChallenge.progress = challengePercent
            } else {
                pbChallenge.visibility = View.GONE
            }

            setupBooksByMonthChart(holder.itemView, curYear.yearBooksByMonth)
        }

        if (position == 0) {
            holder.itemView.clChallenge.setOnClickListener {
                callChallengeDialog(foundYear, it, challengeBooksRead)
            }

            holder.itemView.apply {
                if (foundYear == null) {
                    tvChallengeValue.text = resources.getText(R.string.tvChallengeNotSet)
                }
            }
        } else {
            holder.itemView.apply {
                if (foundYear == null) {
                    clChallenge.visibility = View.GONE
                }
            }
        }
    }

    private fun setupBooksByMonthChart(itemView: View, yearBooksByMonth: Array<Int>) {
        monthsList = arrayListOf(
            itemView.resources.getString(R.string.month_1_short),
            itemView.resources.getString(R.string.month_2_short),
            itemView.resources.getString(R.string.month_3_short),
            itemView.resources.getString(R.string.month_4_short),
            itemView.resources.getString(R.string.month_5_short),
            itemView.resources.getString(R.string.month_6_short),
            itemView.resources.getString(R.string.month_7_short),
            itemView.resources.getString(R.string.month_8_short),
            itemView.resources.getString(R.string.month_9_short),
            itemView.resources.getString(R.string.month_10_short),
            itemView.resources.getString(R.string.month_11_short),
            itemView.resources.getString(R.string.month_12_short)
        )

        val entries: ArrayList<BarEntry> = ArrayList()
        entries.add(BarEntry(0f, yearBooksByMonth[0].toFloat()))
        entries.add(BarEntry(1f, yearBooksByMonth[1].toFloat()))
        entries.add(BarEntry(2f, yearBooksByMonth[2].toFloat()))
        entries.add(BarEntry(3f, yearBooksByMonth[3].toFloat()))
        entries.add(BarEntry(4f, yearBooksByMonth[4].toFloat()))
        entries.add(BarEntry(5f, yearBooksByMonth[5].toFloat()))
        entries.add(BarEntry(6f, yearBooksByMonth[6].toFloat()))
        entries.add(BarEntry(7f, yearBooksByMonth[7].toFloat()))
        entries.add(BarEntry(8f, yearBooksByMonth[8].toFloat()))
        entries.add(BarEntry(9f, yearBooksByMonth[9].toFloat()))
        entries.add(BarEntry(10f, yearBooksByMonth[10].toFloat()))
        entries.add(BarEntry(11f, yearBooksByMonth[11].toFloat()))

        val barDataSet = BarDataSet(entries, "")
        barDataSet.setColors(*ColorTemplate.COLORFUL_COLORS)

        var data = BarData(barDataSet)
//        data.setValueFormatter(MyValueFormatter())

//        data.setDefaultValueFormatter(DefaultValueFormatter(1))
        data.setValueFormatter(DefaultValueFormatter(0))
//        data.setValueFormatter(YourValueFormatter())
        itemView.lcMonths.data = data


        //hide grid lines
        itemView.lcMonths.axisLeft.setDrawGridLines(false)
        itemView.lcMonths.xAxis.setDrawGridLines(false)
        itemView.lcMonths.xAxis.setDrawAxisLine(false)

        //remove right y-axis
        itemView.lcMonths.axisRight.isEnabled = false
        //remove left y-axis
        itemView.lcMonths.axisLeft.isEnabled = false

        //remove legend
        itemView.lcMonths.legend.isEnabled = false

        //remove description label
        itemView.lcMonths.description.isEnabled = false
//        itemView.lcMonths.description.isEnabled = true


        //add animation
//        itemView.lcMonths.animateY(3000)
        itemView.lcMonths.animateY(750)



        itemView.lcMonths.xAxis.position = XAxis.XAxisPosition.BOTTOM
//        itemView.lcMonths.xAxis.labelRotationAngle = -90F

        itemView.lcMonths.xAxis.valueFormatter = IndexAxisValueFormatter(monthsList)
//        itemView.lcMonths.defaultValueFormatter = MyValueFormatter()

        //draw chart
        itemView.lcMonths.invalidate()
    }

    private fun setCardsAnimation(view: View) {
        val statCards = listOf<View>(
            view.clMonths,
            view.clBooksRead,
            view.clPagesRead,
            view.clAvgRating,
            view.clQuickestRead,
            view.clLongestBook,
            view.clAvgReadingTime,
            view.clAvgPages,
            view.clShortestBook
        )

        var animDuration = 200L
        var scaleSmall = 0.95F
        var scaleBig = 1F


        for (card in statCards) {
            card.setOnClickListener {
                card.animate().scaleX(scaleSmall).setDuration(animDuration).start()
                card.animate().scaleY(scaleSmall).setDuration(animDuration).start()

                MainScope().launch {
                    delay(animDuration)
                    card.animate().scaleX(scaleBig).setDuration(animDuration).start()
                    card.animate().scaleY(scaleBig).setDuration(animDuration).start()
                }
            }

        }
    }

    private fun callChallengeDialog(foundYear: Year?, it: View, challengeBooksRead: String) {
        if (foundYear != null) {
            ChallengeDialog(it.context,
                foundYear,
                object : ChallengeDialogListener {
                    override fun onSaveButtonClicked(year: Year) {
                        viewModel.upsertYear(year)
                    }
                }
            ).show()
        } else {
            ChallengeDialog(it.context,
                Year(
                    Calendar.getInstance().get(Calendar.YEAR).toString(),
                    challengeBooksRead.toInt()
                ),
                object : ChallengeDialogListener {
                    override fun onSaveButtonClicked(year: Year) {
                        viewModel.upsertYear(year)
                    }
                }
            ).show()
        }
    }

    private fun convertLongToDays(time: Long): String {
        return TimeUnit.MILLISECONDS.toDays(time).toString()
    }
}