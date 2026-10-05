#include <QApplication>

#include "liveviewwindow.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    LiveViewWindow window;
    window.resize(1000, 760);
    window.show();

    return app.exec();
}
