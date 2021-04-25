
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StartOnboarding extends StatefulWidget {

  @override
  _StartOnboardingState createState() => _StartOnboardingState();

}

class _StartOnboardingState extends State<StartOnboarding> {
  final _controller = PageController();

  int _currentIndex = 0;

  createCircle(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 100),
      margin: EdgeInsets.only(right: 4),
      height: 5,
      width: _currentIndex == index ? 15 : 5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        color: data[_currentIndex].backgroundColor,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                scrollDirection: Axis.horizontal,
                controller: _controller,
                onPageChanged: (value) {
                  setState(() {
                    _currentIndex = value;
                  });
                },
                children: data.map((e) => ExplanationPage(data: e)).toList()
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  data.length,
                  (index) => createCircle(index)
                ),
              )
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      "Pular",
                      style: TextStyle(
                        fontSize: 17.0,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      int nextPage = _currentIndex + 1;
                      if (nextPage < data.length) {
                        _controller.jumpToPage(nextPage);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          (_currentIndex == data.length - 1) ? "Concluir" : "Próximo",
                          style: TextStyle(
                            fontSize: 17.0,
                            color: Colors.white,
                          ),
                        ),
                        if (_currentIndex < data.length - 1) Icon(
                          Icons.arrow_right_alt,
                          color: Colors.white,
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
        ),
      ),
    );
  }

}

class ExplanationPage extends StatelessWidget {

  final ExplanationData data;

  ExplanationPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            data.localImageSrc,
            height: 300.0,
          ),
          SizedBox(
            height: 35.0,
          ),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: 25.0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        ]
      ),
    );
  }

}

class ExplanationData {
  final String title;
  final String description;
  final String localImageSrc;
  final Color backgroundColor;

  ExplanationData({
    required this.title,
    required this.description,
    required this.localImageSrc,
    required this.backgroundColor
  });
}

List<ExplanationData> data = [
  ExplanationData(
    description: "Adicione seus documentos, livros, gadgets ou qualquer outra coisa. "
        "Assim, você sempre saberá onde e com quem estão!",
    title: "Lembre das suas coisas",
    localImageSrc: "assets/onboarding_1.png",
    backgroundColor: Colors.orange.shade400,
  ),
  ExplanationData(
    description: "Crie categorias e organize seus itens pessoais como achar melhor. "
        "Lembre-se que sempre é possível editar e reorganizar tudo por aqui!",
    title: "Organize seus objetos",
    localImageSrc: "assets/onboarding_2.png",
    backgroundColor: Colors.blue.shade400,
  ),
  ExplanationData(
    description: "Você pode pesquisar por seus itens usando vários filtros. "
        "Dessa forma, é mais fácil encontrar suas coisas aqui e no \"mundo real\"",
    title: "Pesquise com filtros",
    localImageSrc: "assets/onboarding_3.png",
    backgroundColor: Colors.green.shade400,
  ),
];